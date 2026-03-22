# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/).

## [Unreleased]

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
