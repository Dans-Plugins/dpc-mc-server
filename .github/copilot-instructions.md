# Copilot Instructions

This repository follows the DPC (Dans Plugins Community) conventions defined at
https://github.com/Dans-Plugins/dpc-conventions. Read those conventions before
making any changes.

## Technology Stack

- Infrastructure type: Docker / Docker Compose
- Server platform: Spigot (Minecraft)
- Scripting language: Bash
- Configuration: Environment variables (`.env` / `sample.env`)

## Project Structure

- `Dockerfile` – Builds the Spigot server image
- `compose.yml` – Docker Compose service definition
- `sample.env` – Template environment file with all configurable variables
- `resources/` – Static assets copied into the image
  - `resources/jars/` – Pre-built plugin JARs included in the image
  - `resources/post-create.sh` – Entrypoint script that configures and starts the server
- `deposit-box/` – Host-mounted directory for dropping in additional plugin JARs or config overrides
- `up.sh` – Convenience script to start the server
- `down.sh` – Convenience script to stop the server

## Coding Conventions

- All server configuration is driven by environment variables defined in `sample.env`.
- Plugin toggles follow the pattern `<PLUGIN_NAME>_ENABLED=true|false`.
- The `post-create.sh` script uses the `manage_plugin_dependencies` function to copy or remove plugin JARs based on environment variable values.
- Do not hard-code values that should be configurable; always add a corresponding entry to `sample.env` and `CONFIG.md`.
- Keep `sample.env` in sync with `compose.yml` – every variable referenced in `compose.yml` must have a default in `sample.env`.

## Contribution Workflow

- Branch from `develop` for all changes.
- Open a pull request against `develop`, not `main`.
- Reference the related GitHub issue in every pull request description.
