#!/bin/bash
#
# Tests for the up.sh and down.sh convenience scripts.
#
# The documented invocation is "./up.sh" and "./down.sh" on a machine that has
# the Docker Compose v2 plugin installed, so each script must be executable,
# declare a bash shebang, and call "docker compose" rather than the end-of-life
# v1 "docker-compose" binary. Nothing here runs Docker.
#
# Usage: ./tests/test-scripts.sh

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
SCRIPTS="up.sh down.sh"

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

# Test: the script is tracked with the executable bit set, so "./up.sh" works
# on a fresh clone without a "bash up.sh" workaround
test_script_is_executable() {
    local script="$1"
    local mode
    mode="$(git -C "$REPO_ROOT" ls-files --stage "$script" | awk '{print $1}')"
    if [ "$mode" = "100755" ]; then
        report_pass "$script is tracked as executable"
    else
        report_fail "$script is tracked with mode '${mode:-untracked}', expected 100755"
    fi
}

# Test: the script declares a bash shebang instead of relying on the invoking
# shell's ENOEXEC fallback
test_script_has_bash_shebang() {
    local script="$1"
    if [ "$(head -n 1 "$REPO_ROOT/$script")" = "#!/bin/bash" ]; then
        report_pass "$script starts with #!/bin/bash"
    else
        report_fail "$script does not start with #!/bin/bash"
    fi
}

# Test: the script calls the Compose v2 plugin, matching the "docker compose"
# commands documented in README.md, USER_GUIDE.md and COMMANDS.md
test_script_uses_compose_v2() {
    local script="$1"
    if grep -q 'docker-compose' "$REPO_ROOT/$script"; then
        report_fail "$script calls the Compose v1 docker-compose binary"
    elif grep -qE '(^|[^a-z-])docker compose ' "$REPO_ROOT/$script"; then
        report_pass "$script calls docker compose"
    else
        report_fail "$script does not call docker compose"
    fi
}

# Test: the script has valid bash syntax
test_script_syntax_is_valid() {
    local script="$1"
    if bash -n "$REPO_ROOT/$script" 2> /dev/null; then
        report_pass "$script passes bash -n"
    else
        report_fail "$script fails bash -n"
    fi
}

# Main Process
for script in $SCRIPTS; do
    test_script_is_executable "$script"
    test_script_has_bash_shebang "$script"
    test_script_uses_compose_v2 "$script"
    test_script_syntax_is_valid "$script"
done

if [ "$failures" -eq 0 ]; then
    echo "SCRIPT TESTS: PASS"
    exit 0
fi

echo "SCRIPT TESTS: FAIL ($failures failing)"
exit 1
