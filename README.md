# Dan's Plugins Community Minecraft Server

## Description

DPC MC Server is an infrastructure-as-code Minecraft server for the Dan's Plugins Community. It uses Docker to provide a reproducible, configurable Spigot server pre-loaded with a curated set of DPC plugins.

## Installation

### First Time Installation

1. Install [Docker](https://docs.docker.com/get-docker/).
2. Install [Docker Compose](https://docs.docker.com/compose/install/).
3. Install [Git](https://git-scm.com/downloads).
4. Clone this repository: `git clone https://github.com/Dans-Plugins/dpc-mc-server.git`
5. Copy `sample.env` to `.env` and configure as needed (see [Configuration Guide](CONFIG.md)).
6. Start the server: `./up.sh`

### Included Plugins

The server ships with the following DPC plugins (each can be toggled on or off via `.env`):

- [ActivityTracker](https://github.com/Dans-Plugins/ActivityTracker)
- [AlternateAccountFinder](https://github.com/Dans-Plugins/AlternateAccountFinder)
- [Currencies](https://github.com/Dans-Plugins/Currencies)
- [Dans-Essentials](https://github.com/Dans-Plugins/Dans-Essentials)
- [Dans-Set-Home](https://github.com/Dans-Plugins/Dans-Set-Home)
- [Dans-Spawn-System](https://github.com/Dans-Plugins/Dans-Spawn-System)
- [Fiefs](https://github.com/Dans-Plugins/Fiefs)
- [FoodSpoilage](https://github.com/Dans-Plugins/FoodSpoilage)
- [Mailboxes](https://github.com/Dans-Plugins/Mailboxes)
- [Medieval-Economy](https://github.com/Dans-Plugins/Medieval-Economy)
- [Medieval-Factions](https://github.com/Dans-Plugins/Medieval-Factions)
- [Medieval-Roleplay-Engine](https://github.com/Dans-Plugins/Medieval-Roleplay-Engine)
- [More-Recipes](https://github.com/Dans-Plugins/More-Recipes)
- [NetherAccessController](https://github.com/Dans-Plugins/NetherAccessController)
- [NoMoreCreepers](https://github.com/Dans-Plugins/NoMoreCreepers)
- [PlayerLore](https://github.com/Dans-Plugins/PlayerLore)
- [SimpleSkills](https://github.com/Dans-Plugins/SimpleSkills)
- [WildPets](https://github.com/Dans-Plugins/WildPets)

Third-party plugins also included: Dynmap, BlueMap, PlaceholderAPI, ViaVersion, ViaBackwards.

## Usage

### Documentation

- [User Guide](USER_GUIDE.md) – Getting started and common scenarios
- [Commands Reference](COMMANDS.md) – Docker and server management commands
- [Configuration Guide](CONFIG.md) – All environment variable options

## Support

You can find the support Discord server [here](https://discord.gg/xXtuAQ2).

### Experiencing a bug?

Please fill out a bug report [here](https://github.com/Dans-Plugins/dpc-mc-server/issues/new).

- [Known Bugs](https://github.com/Dans-Plugins/dpc-mc-server/issues?q=is%3Aissue+is%3Aopen+label%3Abug)

## Contributing

- [CONTRIBUTING.md](CONTRIBUTING.md)
- [Notes for Developers](https://github.com/Dans-Plugins/dpc-mc-server/wiki)

## Testing

### Validating the Docker Build

```
docker build -t dpc-mc-server-test .
```

A successful build produces a `Successfully built` message at the end of the output.

## Development

### Test Server with Docker

A Docker Compose setup is available for local development and testing.

#### Setup

1. Copy `sample.env` to `.env` and configure as needed.
2. Start the test server: `./up.sh`

The server will be accessible at `localhost:25565`.

#### Modifying Server Files

1. While the server is running, run `docker exec -it dpc-mc-server /bin/bash`.
2. You will now be in the server's filesystem. Modify files as needed.
3. When you are done, run `exit` to exit the container.
4. Run `docker compose restart` to restart the server with your changes.

#### Stopping the Test Server

```
./down.sh
```

## Authors and Acknowledgement

### Developers

| Name | Main Contributions |
|------|--------------------|
| [DanTheTechMan](https://github.com/dmccoystephenson) | Creator and maintainer |

## License

This project is licensed under the [GNU General Public License v3.0](LICENSE) (GPL-3.0).

You are free to use, modify, and distribute this software, provided that:

- Source code is made available under the same license when distributed.
- Changes are documented and attributed.
- No additional restrictions are applied.

See the [LICENSE](LICENSE) file for the full text of the GPL-3.0 license.

## Project Status

This project is in active development.
