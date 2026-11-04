#!/bin/bash
#
# Tests for the wiring between the configuration files.
#
# A configurable value lives in several files at once: its default in
# sample.env, its pass-through in the compose.yml environment list, its
# documentation in CONFIG.md (in sample.env order), and — for a plugin
# toggle — a JAR under resources/jars/ whose name begins with the prefix given
# to manage_plugin_dependencies. The Minecraft version is additionally repeated as
# the Dockerfile's hardcoded BuildTools --rev argument, and every bundled plugin
# is listed in README.md and COMMANDS.md as well, and the required dependencies
# declared in the bundled JARs' plugin.yml files are tabulated in CONFIG.md.
# The ports and container name set in compose.yml are repeated in USER_GUIDE.md
# and in the documented docker logs/exec commands, and the files the entrypoint
# rewrites on every start are listed in USER_GUIDE.md. The plugin directories it
# edits must be spelled as the bundled plugins name themselves in plugin.yml,
# since Spigot creates each data directory from that name. The directories the
# entrypoint works in are set by the Dockerfile and the compose.yml mounts, and
# are repeated in the documented commands. Nothing else checks that these agree,
# and a disagreement either builds cleanly and then fails at startup or silently
# starts the server without a plugin. Nothing here runs Docker.
#
# Usage: ./tests/test-wiring.sh

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
SAMPLE_ENV="$REPO_ROOT/sample.env"
COMPOSE_FILE="$REPO_ROOT/compose.yml"
ENTRYPOINT="$REPO_ROOT/resources/post-create.sh"
JARS_DIR="$REPO_ROOT/resources/jars"
DOCKERFILE="$REPO_ROOT/Dockerfile"
CONFIG_DOC="$REPO_ROOT/CONFIG.md"
USER_GUIDE="$REPO_ROOT/USER_GUIDE.md"

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

# Function: Print the sample.env variables that CONFIG.md documents, in the
# order CONFIG.md documents them: each "## <VAR>" section heading and each
# toggle-table row ("| `<VAR>` | `<default>` | [Plugin](...) |"). Rows of the
# Plugin Dependencies table carry no link and are not counted.
documented_variable_order() {
    # The backticks are literal: they delimit the variable name in each table row
    # shellcheck disable=SC2016
    awk '
        /^## [A-Z0-9_]+$/ { print $2; next }
        /^\| `[A-Z0-9_]+` \| `[^`]*` \| \[/ { split($0, cells, "`"); print cells[2] }
    ' "$CONFIG_DOC"
}

# Function: Print the sorted external links ("[Name](https://...)") that
# appear between a heading line and the next line starting with a stop marker
plugin_links_in_section() {
    local file="$1"
    local heading="$2"
    local stop="$3"
    awk -v heading="$heading" -v stop="$stop" '
        $0 == heading { in_section = 1; next }
        in_section && index($0, stop) == 1 { exit }
        in_section { print }
    ' "$file" | grep -oE '\[[^]]+\]\(https?://[^)]+\)' | sort -u
}

# Function: Print the sorted plugin links from the toggle tables in CONFIG.md
config_plugin_links() {
    # The backticks are literal: they delimit the variable name in each table row
    # shellcheck disable=SC2016
    grep -E '^\| `[A-Z0-9_]+_ENABLED` \|' "$CONFIG_DOC" | grep -oE '\[[^]]+\]\(https?://[^)]+\)' | sort -u
}

# Function: List "<prefix> <toggle>" for every manage_plugin_dependencies call
plugin_calls() {
    grep -E '^manage_plugin_dependencies ' "$ENTRYPOINT" | tr -d '"' | awk '{print $2, $3}'
}

# Function: Print the bundled JAR that a manage_plugin_dependencies prefix installs
jar_for_prefix() {
    find "$JARS_DIR" -maxdepth 1 -type f -name "$1-*.jar" | head -n 1
}

# Function: Print the plugin name from a JAR's plugin.yml on the first line,
# then each plugin named in its required "depend:" list on a line of its own.
# Both the inline ("depend: [A, B]") and block ("- A") list forms are read.
plugin_name_and_requirements() {
    unzip -p "$1" plugin.yml | tr -d "\r\"'" | awk '
        /^name:/ { name = $0; sub(/^name:[ \t]*/, "", name); sub(/[ \t]+$/, "", name) }
        /^depend:/ {
            in_depend = 1
            line = $0
            sub(/^depend:/, "", line)
            gsub(/\[/, " ", line)
            gsub(/\]/, " ", line)
            gsub(/,/, " ", line)
            requirements = requirements " " line
            next
        }
        in_depend && /^[ \t]*- / { line = $0; sub(/^[ \t]*- /, "", line); requirements = requirements " " line; next }
        { in_depend = 0 }
        END {
            print name
            count = split(requirements, required, " ")
            for (i = 1; i <= count; i++) print required[i]
        }
    '
}

# Function: Print the sorted dependency-table rows that the bundled JARs imply:
# one "| `<toggle>` | `<required toggle>` |" row for every required dependency
# of a bundled plugin on another bundled plugin
required_dependency_rows() {
    local plugins
    local prefix
    local var
    local jar
    local required
    local required_var
    plugins="$(plugin_calls | while read -r prefix var; do
        jar="$(jar_for_prefix "$prefix")"
        if [ -n "$jar" ]; then
            echo "$(plugin_name_and_requirements "$jar" | head -n 1) $var"
        fi
    done)"
    while read -r prefix var; do
        jar="$(jar_for_prefix "$prefix")"
        if [ -z "$jar" ]; then
            continue
        fi
        while read -r required; do
            required_var="$(echo "$plugins" | awk -v name="$required" '$1 == name {print $2}')"
            if [ -n "$required_var" ]; then
                echo "| \`$var\` | \`$required_var\` |"
            fi
        done < <(plugin_name_and_requirements "$jar" | tail -n +2)
    done < <(plugin_calls) | sort
}

# Function: Print the sorted rows of the CONFIG.md "## Plugin Dependencies" table
documented_dependency_rows() {
    # The backticks are literal: they delimit the variable names in each table row
    # shellcheck disable=SC2016
    awk '
        $0 == "## Plugin Dependencies" { in_section = 1; next }
        in_section && /^## / { exit }
        in_section { print }
    ' "$CONFIG_DOC" | grep -E '^\| `[A-Z0-9_]+_ENABLED` \| `[A-Z0-9_]+_ENABLED` \|$' | sort
}

# Function: Print the sorted host ports that the compose.yml ports list publishes
compose_published_ports() {
    awk '
        /^ +ports:/ { in_ports = 1; next }
        in_ports && /^ +- / { print; next }
        in_ports { exit }
    ' "$COMPOSE_FILE" | tr -d ' "-' | awk -F ':' '{print $(NF - 1)}' | sort -u
}

# Function: Print the sorted ports named on the USER_GUIDE.md "- Ports" prerequisite line
documented_host_ports() {
    # The backticks are literal: they delimit each port number on the line
    # shellcheck disable=SC2016
    grep -E '^- Ports ' "$USER_GUIDE" | grep -oE '`[0-9]+`' | tr -d '`' | sort -u
}

# Function: Print the container name given to every "docker logs" and
# "docker exec" command in the current documentation, one per line
documented_container_names() {
    local doc
    for doc in README.md USER_GUIDE.md COMMANDS.md CONFIG.md CONTRIBUTING.md; do
        grep -oE 'docker (logs|exec)( -[a-z]+)* [A-Za-z0-9_.-]+' "$REPO_ROOT/$doc" | awk '{print $NF}'
    done
}

# Function: Print the sorted literal paths that post-create.sh writes as
# "$SERVER_DIR"/<path>, outside setup_server and start_server, which only run
# on first setup or launch the server, and outside manage_plugin_dependencies,
# whose per-plugin JARs the guide describes generically. A path built from a
# variable ends at the variable and is left out.
entrypoint_rewritten_paths() {
    # The dollar sign is literal: the paths are matched as written in the script
    # shellcheck disable=SC2016
    awk '
        /^[a-z_]+\(\) \{/ { name = $1; sub(/\(\)$/, "", name); next }
        /^\}/ { name = ""; next }
        name != "setup_server" && name != "start_server" && name != "manage_plugin_dependencies" { print }
    ' "$ENTRYPOINT" | grep -oE '"[$]SERVER_DIR"/[A-Za-z0-9_./-]+' | cut -d '/' -f 2- | grep -v '/$' | sort -u
}

# Function: Print the sorted plugin data directories that post-create.sh names
# as "$SERVER_DIR"/plugins/<directory>/...
entrypoint_plugin_directories() {
    # The dollar sign is literal: the paths are matched as written in the script
    # shellcheck disable=SC2016
    grep -oE '"[$]SERVER_DIR"/plugins/[A-Za-z0-9_.-]+/' "$ENTRYPOINT" | cut -d '/' -f 3 | sort -u
}

# Function: Print the "### Modifying Server Files" section of USER_GUIDE.md
modifying_server_files_section() {
    awk '
        $0 == "### Modifying Server Files" { in_section = 1; next }
        in_section && /^#/ { exit }
        in_section { print }
    ' "$USER_GUIDE"
}

# Function: Print the value that post-create.sh assigns to a top-level variable
entrypoint_variable() {
    grep -E "^$1=" "$ENTRYPOINT" | head -n 1 | cut -d '=' -f 2- | tr -d '"'
}

# Function: Print the container path that compose.yml mounts a source at
compose_mount_target() {
    awk -v wanted="$1" '
        $1 == "source:" { matched = ($2 == wanted); next }
        matched && $1 == "target:" { print $2; exit }
    ' "$COMPOSE_FILE"
}

# Function: Print the name of the service that compose.yml defines
compose_service_name() {
    grep -A 1 -E '^services:' "$COMPOSE_FILE" | tail -n 1 | tr -d ' :'
}

# Function: Print the last WORKDIR in the Dockerfile lines read from stdin
last_workdir() {
    grep -E '^WORKDIR ' | tail -n 1 | awk '{print $2}'
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

# Test: the Dockerfile starts the entrypoint in exec form. The shell form wraps
# it in "/bin/sh -c", which becomes PID 1 and does not pass SIGTERM on, so
# "docker stop" kills the server instead of letting it save and shut down.
test_entrypoint_uses_exec_form() {
    local entrypoint
    entrypoint="$(grep -E '^ENTRYPOINT ' "$DOCKERFILE")"
    if [ "$entrypoint" = 'ENTRYPOINT ["/resources/post-create.sh"]' ]; then
        report_pass "the Dockerfile ENTRYPOINT uses the exec form"
    else
        report_fail "the Dockerfile ENTRYPOINT is '$entrypoint', expected the exec form 'ENTRYPOINT [\"/resources/post-create.sh\"]'"
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

# Test: CONFIG.md documents the sample.env variables in the order sample.env
# assigns them, as its introduction promises, so a reader comparing the two
# files side by side finds each variable where they expect it
test_variables_are_documented_in_sample_env_order() {
    local expected
    local documented
    expected="$(sample_env_variables)"
    documented="$(documented_variable_order)"
    if [ -n "$expected" ] && [ "$documented" = "$expected" ]; then
        report_pass "CONFIG.md documents the sample.env variables in sample.env order"
    else
        report_fail "CONFIG.md documents the variables in a different order from sample.env: $(paste -d ' ' <(echo "$expected") <(echo "$documented") | awk '$1 != $2 { printf "variable %d is %s in sample.env but %s in CONFIG.md", NR, ($1 == "" ? "absent" : $1), ($2 == "" ? "absent" : $2); exit }')"
    fi
}

# Test: every plugin toggle in sample.env is handed to manage_plugin_dependencies
# and every variable handed to it has a default in sample.env. A toggle with no
# call is accepted and then ignored; a call with no default reads an empty value,
# which the entrypoint rejects as fatal.
test_every_toggle_has_a_plugin_call() {
    local toggles
    local called
    local unmatched
    toggles="$(grep -oE '^[A-Z0-9_]+_ENABLED=' "$SAMPLE_ENV" | tr -d '=' | sort -u)"
    called="$(grep -E '^manage_plugin_dependencies ' "$ENTRYPOINT" | tr -d '"' | awk '{print $3}' | sort -u)"
    unmatched="$(comm -3 <(echo "$toggles") <(echo "$called") | tr -d '\t' | tr '\n' ' ')"
    if [ -n "$toggles" ] && [ -z "$unmatched" ]; then
        report_pass "every plugin toggle in sample.env has a manage_plugin_dependencies call, and vice versa"
    else
        report_fail "toggles present in only one of sample.env and the manage_plugin_dependencies calls: $unmatched"
    fi
}

# Test: README.md and COMMANDS.md list the same plugins, with the same links, as
# the CONFIG.md toggle tables, so no document advertises a plugin the server
# does not bundle or omits one that it does
test_plugin_lists_agree() {
    local configured
    local listed
    local doc
    configured="$(config_plugin_links)"
    if [ -z "$configured" ]; then
        report_fail "no plugin links found in the CONFIG.md toggle tables"
        return
    fi
    for doc in README COMMANDS; do
        if [ "$doc" = "README" ]; then
            listed="$(plugin_links_in_section "$REPO_ROOT/README.md" "### Included Plugins" "## ")"
        else
            listed="$(plugin_links_in_section "$REPO_ROOT/COMMANDS.md" "## Plugin Commands" "## ")"
        fi
        if [ "$listed" = "$configured" ]; then
            report_pass "$doc.md lists the same plugins as CONFIG.md"
        else
            report_fail "$doc.md and CONFIG.md list different plugins: $(comm -3 <(echo "$listed") <(echo "$configured") | tr -d '\t' | tr '\n' ' ')"
        fi
    done
}

# Test: the CONFIG.md "Plugin Dependencies" table lists exactly the required
# dependencies that the bundled JARs declare on each other. A JAR is binary, so
# a replacement that gains or loses a "depend:" entry shows no diff, and the
# table would otherwise go stale unnoticed.
test_dependency_table_matches_plugin_metadata() {
    local expected
    local documented
    if ! command -v unzip > /dev/null; then
        report_fail "unzip is not installed, so the plugin.yml of each bundled JAR cannot be read"
        return
    fi
    expected="$(required_dependency_rows)"
    documented="$(documented_dependency_rows)"
    if [ "$documented" = "$expected" ]; then
        report_pass "the CONFIG.md dependency table matches the depend: entries of the bundled JARs"
    else
        report_fail "the CONFIG.md dependency table and the bundled JARs disagree (rows found in only one of them): $(comm -3 <(echo "$documented") <(echo "$expected") | tr -d '\t' | tr '\n' ' ')"
    fi
}

# Test: the ports USER_GUIDE.md tells users to free on their host are exactly
# the host ports compose.yml publishes, so a port added, removed, or remapped in
# compose.yml cannot leave the prerequisites describing a different set
test_published_ports_are_documented() {
    local published
    local documented
    published="$(compose_published_ports)"
    documented="$(documented_host_ports)"
    if [ -n "$published" ] && [ "$published" = "$documented" ]; then
        report_pass "USER_GUIDE.md lists the host ports that compose.yml publishes ($(echo "$published" | paste -sd ' '))"
    else
        report_fail "compose.yml publishes host ports '$(echo "$published" | paste -sd ' ')' but USER_GUIDE.md lists '$(echo "$documented" | paste -sd ' ')'"
    fi
}

# Test: every "docker logs" and "docker exec" command in the documentation names
# the container_name that compose.yml sets, since a renamed container makes each
# of those commands fail with "No such container"
test_documented_container_name_matches_compose() {
    local expected
    local names
    local mismatched
    expected="$(grep -E '^ +container_name:' "$COMPOSE_FILE" | awk '{print $2}')"
    names="$(documented_container_names)"
    if [ -z "$expected" ] || [ -z "$names" ]; then
        report_fail "no container_name in compose.yml ('$expected') or no docker logs/exec commands in the documentation"
        return
    fi
    mismatched="$(echo "$names" | grep -vxF -- "$expected" | sort -u | paste -sd ' ')"
    if [ -z "$mismatched" ]; then
        report_pass "every documented docker logs/exec command names the compose.yml container ($expected)"
    else
        report_fail "documented docker logs/exec commands name '$mismatched' but compose.yml sets container_name '$expected'"
    fi
}

# Test: every file the entrypoint rewrites on each start is named in the
# USER_GUIDE.md "Modifying Server Files" section, which warns that edits to
# those files do not survive a restart. A rewrite added to post-create.sh
# would otherwise leave that list incomplete with nothing to flag it.
test_rewritten_files_are_documented() {
    local paths
    local section
    local path
    local undocumented=""
    paths="$(entrypoint_rewritten_paths)"
    section="$(modifying_server_files_section)"
    if [ -z "$paths" ] || [ -z "$section" ]; then
        report_fail "no rewritten paths found in post-create.sh or no '### Modifying Server Files' section in USER_GUIDE.md"
        return
    fi
    while read -r path; do
        if ! echo "$section" | grep -qF -- "\`$path\`"; then
            undocumented="$undocumented $path"
        fi
    done <<< "$paths"
    if [ -z "$undocumented" ]; then
        report_pass "USER_GUIDE.md names every file the entrypoint rewrites on start ($(echo "$paths" | paste -sd ' '))"
    else
        report_fail "files the entrypoint rewrites on start but USER_GUIDE.md does not name:$undocumented"
    fi
}

# Test: every plugin data directory the entrypoint edits is spelled exactly as a
# bundled plugin names itself in plugin.yml. Spigot creates plugins/<name>/ from
# that name, case-sensitively, so a directory spelled any other way never exists
# and the edit fails on every start.
test_plugin_directories_match_plugin_names() {
    local names
    local directories
    local directory
    local jar
    local unmatched=""
    if ! command -v unzip > /dev/null; then
        report_fail "unzip is not installed, so the plugin.yml of each bundled JAR cannot be read"
        return
    fi
    names="$(for jar in "$JARS_DIR"/*.jar; do plugin_name_and_requirements "$jar" | head -n 1; done)"
    directories="$(entrypoint_plugin_directories)"
    if [ -z "$directories" ]; then
        report_fail "no plugin data directories found in post-create.sh"
        return
    fi
    while read -r directory; do
        if ! echo "$names" | grep -qxF -- "$directory"; then
            unmatched="$unmatched $directory"
        fi
    done <<< "$directories"
    if [ -z "$unmatched" ]; then
        report_pass "every plugin directory post-create.sh edits matches a bundled plugin's name ($(echo "$directories" | paste -sd ' '))"
    else
        report_fail "plugin directories in post-create.sh that no bundled plugin.yml names (case-sensitive):$unmatched"
    fi
}

# Test: SERVER_DIR is both the path the named volume is mounted at and the
# image's final WORKDIR. Outside the mount the world is written to the container
# layer and lost when the container is recreated. Spigot reads eula.txt and
# plugins/ from its working directory, which start_server does not change, so
# outside the WORKDIR the server ignores everything the entrypoint set up.
test_server_directory_is_mounted_and_is_the_workdir() {
    local server_dir
    local mounted
    local workdir
    server_dir="$(entrypoint_variable SERVER_DIR)"
    mounted="$(compose_mount_target dpcmcserver)"
    workdir="$(last_workdir < "$DOCKERFILE")"
    if [ -n "$server_dir" ] && [ "$server_dir" = "$mounted" ] && [ "$server_dir" = "$workdir" ]; then
        report_pass "SERVER_DIR is the dpcmcserver volume target and the final WORKDIR ($server_dir)"
    else
        report_fail "SERVER_DIR is '$server_dir' but the dpcmcserver volume target is '$mounted' and the final WORKDIR is '$workdir'"
    fi
}

# Test: BUILD_DIR is the WORKDIR that BuildTools runs in, since BuildTools writes
# the Spigot JAR to its working directory and setup_server copies it from BUILD_DIR
test_build_directory_is_the_buildtools_workdir() {
    local build_dir
    local workdir
    build_dir="$(entrypoint_variable BUILD_DIR)"
    workdir="$(sed '/BuildTools.jar --rev/q' "$DOCKERFILE" | last_workdir)"
    if [ -n "$build_dir" ] && [ "$build_dir" = "$workdir" ]; then
        report_pass "BUILD_DIR is the WORKDIR that BuildTools runs in ($build_dir)"
    else
        report_fail "BUILD_DIR is '$build_dir' but BuildTools runs in WORKDIR '$workdir'"
    fi
}

# Test: RESOURCES_DIR is the jars directory of the path the Dockerfile copies
# resources/ to, since every toggle set to "true" copies its JAR from there
test_resources_directory_matches_the_copy_destination() {
    local resources_dir
    local copied_to
    resources_dir="$(entrypoint_variable RESOURCES_DIR)"
    copied_to="$(grep -E '^COPY [.]/resources ' "$DOCKERFILE" | awk '{print $3}')"
    if [ -n "$copied_to" ] && [ "$resources_dir" = "$copied_to/jars" ]; then
        report_pass "RESOURCES_DIR is the jars directory of the Dockerfile's resources copy ($resources_dir)"
    else
        report_fail "RESOURCES_DIR is '$resources_dir' but the Dockerfile copies resources/ to '$copied_to'"
    fi
}

# Test: the commands in CONFIG.md and USER_GUIDE.md that name paths inside the
# container use the directories the entrypoint and compose.yml actually use, and
# the upgrade command in CONFIG.md names the compose.yml service
test_documented_container_paths_match() {
    local server_dir
    local build_dir
    local deposit_dir
    local service
    local missing=""
    local doc
    local command
    server_dir="$(entrypoint_variable SERVER_DIR)"
    build_dir="$(entrypoint_variable BUILD_DIR)"
    deposit_dir="$(compose_mount_target ./deposit-box)"
    service="$(compose_service_name)"
    while IFS='|' read -r doc command; do
        if ! grep -qF -- "$command" "$REPO_ROOT/$doc"; then
            missing="$missing [$doc: $command]"
        fi
    done <<EOF
CONFIG.md|docker compose run --rm --entrypoint cp $service $build_dir/spigot-<MINECRAFT_VERSION>.jar $server_dir/
USER_GUIDE.md|Navigate to \`$server_dir\`
USER_GUIDE.md|cp $deposit_dir/YourPlugin.jar $server_dir/plugins/
EOF
    if [ -n "$server_dir" ] && [ -n "$build_dir" ] && [ -n "$deposit_dir" ] && [ -n "$service" ] && [ -z "$missing" ]; then
        report_pass "the commands in CONFIG.md and USER_GUIDE.md use the service and container paths in force ($service $server_dir $build_dir $deposit_dir)"
    else
        report_fail "documentation does not contain the expected service and container paths:$missing"
    fi
}

# Main Process
test_compose_variables_have_defaults
test_sample_env_variables_reach_the_container
test_every_toggle_has_a_plugin_call
test_every_plugin_prefix_matches_one_jar
test_minecraft_version_matches_build_revision
test_entrypoint_uses_exec_form
test_every_variable_is_documented_with_its_default
test_variables_are_documented_in_sample_env_order
test_plugin_lists_agree
test_dependency_table_matches_plugin_metadata
test_published_ports_are_documented
test_documented_container_name_matches_compose
test_rewritten_files_are_documented
test_plugin_directories_match_plugin_names
test_server_directory_is_mounted_and_is_the_workdir
test_build_directory_is_the_buildtools_workdir
test_resources_directory_matches_the_copy_destination
test_documented_container_paths_match

if [ "$failures" -eq 0 ]; then
    echo "WIRING TESTS: PASS"
    exit 0
fi

echo "WIRING TESTS: FAIL ($failures failing)"
exit 1
