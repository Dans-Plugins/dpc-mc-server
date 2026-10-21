# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/).

## [Unreleased]

### Added

- `tests/test-post-create.sh`, which exercises the plugin-toggle handling in `resources/post-create.sh` against a throwaway directory tree without building an image or starting a server. The script is documented in the Testing sections of `README.md` and `CONTRIBUTING.md`.
- `tests/test-scripts.sh`, which checks that `up.sh` and `down.sh` are tracked as executable, declare a bash shebang, and call the Compose v2 `docker compose` plugin. The script is documented in the Testing sections of `README.md` and `CONTRIBUTING.md`.
- `tests/test-wiring.sh`, which checks that the configuration files agree: `compose.yml` and `sample.env` define and forward the same variables, every `manage_plugin_dependencies` prefix matches exactly one JAR in `resources/jars/` case-sensitively, `MINECRAFT_VERSION` equals the `Dockerfile`'s `--rev` argument, and `CONFIG.md` documents every `sample.env` variable with its actual default. The script is documented in the Testing sections of `README.md` and `CONTRIBUTING.md`.
- Two further checks in `tests/test-wiring.sh`: every `*_ENABLED` toggle in `sample.env` has a `manage_plugin_dependencies` call in `resources/post-create.sh` and every variable passed to one is defined in `sample.env`; and the plugin lists in `README.md` and `COMMANDS.md` match the `CONFIG.md` toggle tables plugin-for-plugin, link-for-link.
- A check in `tests/test-wiring.sh` that the `CONFIG.md` Plugin Dependencies table lists exactly the required dependencies (`depend:`) that the bundled JARs' `plugin.yml` files declare on other bundled plugins. A replaced JAR that gains or loses a requirement shows no reviewable diff, so the table previously could go stale unnoticed. The check reads each JAR with `unzip` and does not run Docker.
- Two checks in `tests/test-wiring.sh` that tie the documentation to `compose.yml`: the ports named under Prerequisites in `USER_GUIDE.md` must be exactly the host ports `compose.yml` publishes, and every `docker logs` and `docker exec` command in `README.md`, `USER_GUIDE.md`, `COMMANDS.md`, `CONFIG.md`, and `CONTRIBUTING.md` must name the `container_name` that `compose.yml` sets. A remapped port or renamed container previously left those instructions wrong with nothing to flag it.
- A `test` job in the `Build` workflow that runs `tests/test-post-create.sh`, `tests/test-scripts.sh`, and `tests/test-wiring.sh` on every push to and pull request against `main`. It runs in parallel with the `build` job and does not wait for the Spigot compile, so toggle-handling, convenience-script, and wiring breakage now fails CI rather than depending on contributors running the scripts by hand.

### Fixed

- Stopping the server now shuts Spigot down cleanly instead of killing it. The `Dockerfile` used the shell form of `ENTRYPOINT`, which runs the entrypoint under `/bin/sh -c`, and `start_server` ran `java` as a child process; neither passed `SIGTERM` on, so `./down.sh` and `docker stop` waited out Docker's 10-second grace period and then killed the server without saving worlds or running plugin shutdown handlers. The `ENTRYPOINT` now uses the exec form and `start_server` runs `exec java`, so `java` receives `SIGTERM` directly. Covered by new cases in `tests/test-post-create.sh` and `tests/test-wiring.sh`; the shutdown itself has not been exercised by a real server start.
- Upgrading a bundled plugin no longer leaves the old version installed on an existing server. With a toggle set to `true`, `manage_plugin_dependencies` copied the bundled JAR into `plugins/` without removing anything first, and because each filename carries its version (`WildPets-1.6.0.jar`, `WildPets-1.7.0.jar`), a rebuilt image started against an existing volume ended up with both JARs side by side. The `true` branch now removes `plugins/<prefix>-*.jar` before copying, so the bundled version always replaces whatever version is installed. A JAR hand-copied into `plugins/` under a bundled plugin's prefix is now replaced on the next start rather than kept beside the bundled one. Covered by a new case in `tests/test-post-create.sh`; the change has not been exercised by a real server start.
- `up.sh` and `down.sh` now call the Compose v2 `docker compose` plugin instead of the end-of-life `docker-compose` v1 binary, which current Docker installations do not ship, so the documented `./up.sh` and `./down.sh` no longer fail with `docker-compose: command not found`. Both scripts are now tracked as executable, declare `#!/bin/bash`, and end with a trailing newline; previously a fresh clone could not run `./up.sh` at all without `chmod +x` first.
- `BLUEMAP_ENABLED=false` now removes an already-installed BlueMap JAR. The call to `manage_plugin_dependencies` was nested inside an `if [ "$BLUEMAP_ENABLED" = "true" ]` block, so the function's "disable" and invalid-value branches were unreachable for BlueMap alone and a server that had once been started with BlueMap enabled kept loading it. Only `update_bluemap_config` remains behind the conditional.
- An unrecognised plugin-toggle value now exits with status `1` instead of `0`. The bare `exit` returned the status of the preceding `echo`, so a typo such as `FIEFS_ENABLED=flase` stopped the container before the server started while reporting a clean shutdown to Docker.
- Corrected the `MINECRAFT_VERSION` description in `CONFIG.md`, which stated that the value is used by BuildTools. BuildTools uses the hardcoded `--rev` argument in the `Dockerfile`; `MINECRAFT_VERSION` only names the Spigot JAR that the entrypoint copies and launches at runtime. The requirement to change both together is now documented.
- Corrected the instructions for enabling or disabling a plugin and for resetting the server in `USER_GUIDE.md`, which told users to apply `.env` changes with `docker compose restart`. That command does not recreate the container, so the edited values never reach it; `./up.sh` is required.

### Changed

- Documented in `CONFIG.md` the required dependencies between bundled plugins — Currencies and Fiefs on Medieval-Factions, ViaBackwards on ViaVersion — as declared in each JAR's `plugin.yml`. Disabling the required plugin leaves the dependent one installed but unloaded by Spigot; the entrypoint does not check this. `USER_GUIDE.md` links to the new section.
- Documented in `USER_GUIDE.md` that the `deposit-box/` directory is a staging area only, with no automatic installation, and described how a deposited JAR interacts with the bundled plugin toggles.
- Added an "Apply a change made to `.env`" entry to `COMMANDS.md` and noted the limitation of `docker compose restart` on the restart entry.
- Listed the bundled third-party plugins in `COMMANDS.md` so that its plugin list matches `README.md` and `CONFIG.md`.
- Noted in `README.md` and `CONFIG.md` that not every bundled plugin is enabled by default and that toggle changes require recreating the container.
- Renamed "Accessing the Server Console" in `USER_GUIDE.md` to "Opening a Shell in the Container". `docker exec -it dpc-mc-server /bin/bash` opens a Bash shell, not the Minecraft console, and the console does not accept typed input because `compose.yml` sets neither `stdin_open` nor `tty`. `COMMANDS.md` now says the same.
- Corrected the "Rebuild the image" entry in `COMMANDS.md`, which described `docker build` as a rebuild "from scratch" for use after updating plugin JARs. The build reuses Docker's layer cache, and the running container keeps the old image until `./up.sh` recreates it.
- Documented in `CONFIG.md` and `USER_GUIDE.md` what the entrypoint rewrites on every start. `ops.json` is regenerated from the `OPERATOR_*` variables each time, so in-game `/op` grants are lost; `CONFIG.md` previously said the operator was set "on first run". Also documented that changing `MINECRAFT_VERSION` does not update an existing server directory, along with how to copy the new Spigot JAR into the volume, and that BlueMap's `accept-download` setting is only applied from the second start with BlueMap enabled.
- Corrected the `docker build` success message in `README.md`. `Successfully built` is printed only by the legacy builder; BuildKit, which current Docker releases use by default, prints a `naming to` step instead.

## [1.0.0] – 2024-01-01

### Added

- Initial Docker-based server infrastructure
- Support for configuring the Minecraft version via `MINECRAFT_VERSION` environment variable
- Operator setup via `OPERATOR_UUID`, `OPERATOR_NAME`, and `OPERATOR_LEVEL` environment variables
- `OVERWRITE_EXISTING_SERVER` flag for clean resets
- Plugin toggles for all included DPC plugins and third-party plugins
- `up.sh` and `down.sh` scripts for starting and stopping the server
- `sample.env` with sensible defaults
- `deposit-box/` volume for dropping in plugin JARs and configuration overrides
