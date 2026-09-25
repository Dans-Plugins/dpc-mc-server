#!/bin/bash
#
# Tests for the wiring between the configuration files.
#
# A configurable value lives in several files at once: its default in
# sample.env, its pass-through in the compose.yml environment list, its
# documentation in CONFIG.md, and — for a plugin toggle — a JAR under
# resources/jars/ whose name begins with the prefix given to
# manage_plugin_dependencies. The Minecraft version is additionally repeated as
# the Dockerfile's hardcoded BuildTools --rev argument. Nothing else checks that
# these agree, and a disagreement either builds cleanly and then fails at
# startup or silently starts the server without a plugin. Nothing here runs
# Docker.
#
# Usage: ./tests/test-wiring.sh

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
SAMPLE_ENV="$REPO_ROOT/sample.env"
COMPOSE_FILE="$REPO_ROOT/compose.yml"
ENTRYPOINT="$REPO_ROOT/resources/post-create.sh"
JARS_DIR="$REPO_ROOT/resources/jars"
DOCKERFILE="$REPO_ROOT/Dockerfile"
CONFIG_DOC="$REPO_ROOT/CONFIG.md"

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

# Function: List the variable names that sample.env assigns
sample_env_variables() {
    grep -oE '^[A-Z0-9_]+=' "$SAMPLE_ENV" | tr -d '='
}

# Function: Print the value that sample.env assigns to a variable
sample_env_value() {
    grep -E "^$1=" "$SAMPLE_ENV" | head -n 1 | cut -d '=' -f 2-
}

# Function: Print the default that CONFIG.md documents for a variable, taken
# from its toggle-table row or from the "**Default:**" line of its section
documented_default() {
    local var="$1"
    awk -v var="$var" '
        index($0, "| `" var "` | `") == 1 {
            split($0, cells, "`")
            print cells[4]
            exit
        }
        $0 == "## " var { in_section = 1; next }
        in_section && /^## / { exit }
        in_section && /^\*\*Default:\*\* `/ {
            split($0, parts, "`")
            print parts[2]
            exit
        }
    ' "$CONFIG_DOC"
}

# Test: every variable compose.yml interpolates has a default in sample.env, so
# a stock configuration never passes an empty value into the container
test_compose_variables_have_defaults() {
    local missing=""
    local var
    while read -r var; do
        if ! grep -qE "^$var=" "$SAMPLE_ENV"; then
            missing="$missing $var"
        fi
    done < <(grep -oE '[$][{][A-Z0-9_]+[}]' "$COMPOSE_FILE" | sed 's/[^A-Z0-9_]//g' | sort -u)
    if [ -z "$missing" ]; then
        report_pass "every variable in compose.yml has a default in sample.env"
    else
        report_fail "variables in compose.yml with no default in sample.env:$missing"
    fi
}

# Test: every variable in sample.env is passed through to the container, since
# post-create.sh only sees what the compose.yml environment list forwards
test_sample_env_variables_reach_the_container() {
    local unforwarded=""
    local var
    while read -r var; do
        if ! grep -qF -- "- $var=\${$var}" "$COMPOSE_FILE"; then
            unforwarded="$unforwarded $var"
        fi
    done < <(sample_env_variables)
    if [ -z "$unforwarded" ]; then
        report_pass "every variable in sample.env is forwarded by compose.yml"
    else
        report_fail "variables in sample.env not forwarded by compose.yml:$unforwarded"
    fi
}

# Test: every prefix passed to manage_plugin_dependencies matches exactly one
# bundled JAR. The glob is case-sensitive, so a prefix whose capitalisation
# differs from the file name copies nothing, and a second JAR for the same
# prefix would be copied into the plugins directory alongside the first.
test_every_plugin_prefix_matches_one_jar() {
    local mismatched=""
    local prefix
    local matches
    while read -r prefix; do
        matches="$(find "$JARS_DIR" -maxdepth 1 -type f -name "$prefix-*.jar" | wc -l)"
        if [ "$matches" -ne 1 ]; then
            mismatched="$mismatched $prefix($matches)"
        fi
    done < <(grep -E '^manage_plugin_dependencies ' "$ENTRYPOINT" | tr -d '"' | awk '{print $2}')
    if [ -z "$mismatched" ]; then
        report_pass "every plugin prefix matches exactly one JAR in resources/jars"
    else
        report_fail "plugin prefixes not matching exactly one JAR (match count in parentheses):$mismatched"
    fi
}

# Test: MINECRAFT_VERSION names the JAR that BuildTools actually produced, so
# it must equal the --rev argument hardcoded in the Dockerfile
test_minecraft_version_matches_build_revision() {
    local version
    local revision
    version="$(sample_env_value MINECRAFT_VERSION)"
    revision="$(grep -oE -- '--rev [^ ]+' "$DOCKERFILE" | awk '{print $2}')"
    if [ -n "$version" ] && [ "$version" = "$revision" ]; then
        report_pass "MINECRAFT_VERSION matches the Dockerfile --rev argument ($version)"
    else
        report_fail "MINECRAFT_VERSION is '$version' but the Dockerfile builds --rev '$revision'"
    fi
}

# Test: every variable in sample.env is documented in CONFIG.md with the same
# default that sample.env actually sets
test_every_variable_is_documented_with_its_default() {
    local undocumented=""
    local var
    local expected
    local documented
    while read -r var; do
        expected="$(sample_env_value "$var")"
        documented="$(documented_default "$var")"
        if [ "$documented" != "$expected" ]; then
            undocumented="$undocumented $var(sample.env='$expected',CONFIG.md='$documented')"
        fi
    done < <(sample_env_variables)
    if [ -z "$undocumented" ]; then
        report_pass "every variable in sample.env is documented in CONFIG.md with its default"
    else
        report_fail "variables missing from CONFIG.md or documented with a different default:$undocumented"
    fi
}

# Main Process
test_compose_variables_have_defaults
test_sample_env_variables_reach_the_container
test_every_plugin_prefix_matches_one_jar
test_minecraft_version_matches_build_revision
test_every_variable_is_documented_with_its_default

if [ "$failures" -eq 0 ]; then
    echo "WIRING TESTS: PASS"
    exit 0
fi

echo "WIRING TESTS: FAIL ($failures failing)"
exit 1
