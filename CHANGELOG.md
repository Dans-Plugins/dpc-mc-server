# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/).

## [Unreleased]

### Added

- `tests/test-post-create.sh`, which exercises the plugin-toggle handling in `resources/post-create.sh` against a throwaway directory tree without building an image or starting a server. The script is documented in the Testing sections of `README.md` and `CONTRIBUTING.md`.

### Fixed

- `BLUEMAP_ENABLED=false` now removes an already-installed BlueMap JAR. The call to `manage_plugin_dependencies` was nested inside an `if [ "$BLUEMAP_ENABLED" = "true" ]` block, so the function's "disable" and invalid-value branches were unreachable for BlueMap alone and a server that had once been started with BlueMap enabled kept loading it. Only `update_bluemap_config` remains behind the conditional.
- An unrecognised plugin-toggle value now exits with status `1` instead of `0`. The bare `exit` returned the status of the preceding `echo`, so a typo such as `FIEFS_ENABLED=flase` stopped the container before the server started while reporting a clean shutdown to Docker.
- Corrected the `MINECRAFT_VERSION` description in `CONFIG.md`, which stated that the value is used by BuildTools. BuildTools uses the hardcoded `--rev` argument in the `Dockerfile`; `MINECRAFT_VERSION` only names the Spigot JAR that the entrypoint copies and launches at runtime. The requirement to change both together is now documented.
- Corrected the instructions for enabling or disabling a plugin and for resetting the server in `USER_GUIDE.md`, which told users to apply `.env` changes with `docker compose restart`. That command does not recreate the container, so the edited values never reach it; `./up.sh` is required.

### Changed

- Documented in `USER_GUIDE.md` that the `deposit-box/` directory is a staging area only, with no automatic installation, and described how a deposited JAR interacts with the bundled plugin toggles.
- Added an "Apply a change made to `.env`" entry to `COMMANDS.md` and noted the limitation of `docker compose restart` on the restart entry.
- Listed the bundled third-party plugins in `COMMANDS.md` so that its plugin list matches `README.md` and `CONFIG.md`.
- Noted in `README.md` and `CONFIG.md` that not every bundled plugin is enabled by default and that toggle changes require recreating the container.

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
