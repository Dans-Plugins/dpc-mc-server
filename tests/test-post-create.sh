#!/bin/bash
#
# Tests for resources/post-create.sh.
#
# The entrypoint's function definitions are sourced in isolation — everything
# above the "# Main Process" marker — so that manage_plugin_dependencies can be
# exercised against a throwaway directory tree without building an image or
# starting a server.
#
# Usage: ./tests/test-post-create.sh

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
ENTRYPOINT="$REPO_ROOT/resources/post-create.sh"

failures=0

# Function: Report a passing assertion
report_pass() {
    echo "[TEST] PASS: $1"
}

# Function: Report a failing assertion and remember it
report_fail() {
    echo "[TEST] FAIL: $1"
    failures=$((failures + 1))
}

# Function: Source the entrypoint's function definitions without running them
#
# The "# Main Process" marker is what separates the definitions from the code
# that runs them, so its absence is treated as a hard error rather than allowed
# to fall through: sourcing the whole entrypoint would run setup_server, which
# deletes the contents of /dpcmcserver.
load_entrypoint_functions() {
    if ! grep -q '^# Main Process$' "$ENTRYPOINT"; then
        report_fail "the '# Main Process' marker is missing from $ENTRYPOINT, so the function definitions cannot be isolated"
        echo "POST-CREATE TESTS: FAIL (1 failing)"
        exit 1
    fi

    local definitions
    definitions="$(mktemp)" || exit 1
    sed '/^# Main Process$/,$d' "$ENTRYPOINT" > "$definitions"
    # shellcheck disable=SC1090
    . "$definitions"
    rm -f "$definitions"
}

# Function: Create a throwaway server directory and JAR resource directory
setup_fixture() {
    FIXTURE_DIR="$(mktemp -d)" || exit 1
    SERVER_DIR="$FIXTURE_DIR/server"
    RESOURCES_DIR="$FIXTURE_DIR/jars"
    mkdir -p "$SERVER_DIR/plugins" "$RESOURCES_DIR"
    touch "$RESOURCES_DIR/TestPlugin-1.0.0.jar"
}

# Function: Remove the throwaway directory tree
teardown_fixture() {
    rm -rf "$FIXTURE_DIR"
}

# Test: a toggle set to "true" copies the plugin JAR into the plugins directory
test_enabled_copies_jar() {
    setup_fixture
    TEST_PLUGIN_ENABLED=true
    manage_plugin_dependencies "TestPlugin" "TEST_PLUGIN_ENABLED" > /dev/null
    if [ -f "$SERVER_DIR/plugins/TestPlugin-1.0.0.jar" ]; then
        report_pass "an enabled toggle copies the plugin JAR"
    else
        report_fail "an enabled toggle did not copy the plugin JAR"
    fi
    teardown_fixture
}

# Test: a toggle set to "false" removes an already-installed plugin JAR
test_disabled_removes_jar() {
    setup_fixture
    touch "$SERVER_DIR/plugins/TestPlugin-1.0.0.jar"
    TEST_PLUGIN_ENABLED=false
    manage_plugin_dependencies "TestPlugin" "TEST_PLUGIN_ENABLED" > /dev/null
    if [ -f "$SERVER_DIR/plugins/TestPlugin-1.0.0.jar" ]; then
        report_fail "a disabled toggle left the plugin JAR in place"
    else
        report_pass "a disabled toggle removes the plugin JAR"
    fi
    teardown_fixture
}

# Test: an unrecognised toggle value aborts with a non-zero status
test_invalid_value_exits_non_zero() {
    setup_fixture
    # shellcheck disable=SC2034  # read by manage_plugin_dependencies via ${!enabled_var}
    TEST_PLUGIN_ENABLED=ture
    local status
    ( manage_plugin_dependencies "TestPlugin" "TEST_PLUGIN_ENABLED" > /dev/null )
    status=$?
    if [ "$status" -ne 0 ]; then
        report_pass "an invalid toggle value exits with status $status"
    else
        report_fail "an invalid toggle value exited with status 0"
    fi
    teardown_fixture
}

# Test: every toggle in sample.env reaches manage_plugin_dependencies through a
# top-level call, so that its "false" and invalid-value branches are reachable
test_every_toggle_is_dispatched_unconditionally() {
    local undispatched=""
    local var
    while read -r var; do
        if ! grep -qE "^manage_plugin_dependencies \"[^\"]+\" \"$var\"\$" "$ENTRYPOINT"; then
            undispatched="$undispatched $var"
        fi
    done < <(grep -oE '^[A-Z_]+_ENABLED' "$REPO_ROOT/sample.env")
    if [ -z "$undispatched" ]; then
        report_pass "every toggle has a top-level manage_plugin_dependencies call"
    else
        report_fail "toggles with no top-level manage_plugin_dependencies call:$undispatched"
    fi
}

# Test: every dispatched toggle has a default in sample.env, so that an unset
# variable never reaches the invalid-value branch on a stock configuration
test_every_dispatched_toggle_has_a_default() {
    local undefined=""
    local var
    while read -r var; do
        if ! grep -qE "^$var=" "$REPO_ROOT/sample.env"; then
            undefined="$undefined $var"
        fi
    done < <(grep -E '^manage_plugin_dependencies ' "$ENTRYPOINT" | tr -d '"' | awk '{print $3}')
    if [ -z "$undefined" ]; then
        report_pass "every dispatched toggle has a default in sample.env"
    else
        report_fail "dispatched toggles with no default in sample.env:$undefined"
    fi
}

# Main Process
load_entrypoint_functions

test_enabled_copies_jar
test_disabled_removes_jar
test_invalid_value_exits_non_zero
test_every_toggle_is_dispatched_unconditionally
test_every_dispatched_toggle_has_a_default

if [ "$failures" -eq 0 ]; then
    echo "POST-CREATE TESTS: PASS"
    exit 0
fi

echo "POST-CREATE TESTS: FAIL ($failures failing)"
exit 1
