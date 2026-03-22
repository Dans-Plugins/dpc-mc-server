# User Guide

## Prerequisites

- [Docker](https://docs.docker.com/get-docker/) installed on your host machine
- [Docker Compose](https://docs.docker.com/compose/install/) installed
- [Git](https://git-scm.com/downloads) installed
- Ports `25565` (game), `8123` (Dynmap), and `8100` (BlueMap) available on your host

## First Steps

1. Clone the repository:
   ```
   git clone https://github.com/Dans-Plugins/dpc-mc-server.git
   cd dpc-mc-server
   ```
2. Copy the sample environment file and edit it:
   ```
   cp sample.env .env
   ```
3. Open `.env` in a text editor and set your operator UUID, name, and which plugins you want enabled. See [CONFIG.md](CONFIG.md) for a full description of every option.
4. Start the server:
   ```
   ./up.sh
   ```
5. Connect to the server in Minecraft at `localhost:25565`.

## Common Scenarios

### Stopping the Server

```
./down.sh
```

### Restarting the Server

```
docker compose restart
```

### Viewing Server Logs

```
docker logs -f dpc-mc-server
```

### Accessing the Server Console

```
docker exec -it dpc-mc-server /bin/bash
```

### Modifying Server Files

1. Run `docker exec -it dpc-mc-server /bin/bash` while the server is running.
2. Navigate to `/dpcmcserver` and edit files as needed.
3. Run `exit` to leave the container.
4. Run `docker compose restart` to apply the changes.

### Adding Plugins to the Deposit Box

Place plugin JARs or override configuration files in the `deposit-box/` directory before starting the server. The container mounts this directory so that its contents are available at `/deposit-box` inside the container.

### Enabling or Disabling a Plugin

Edit `.env` and set the corresponding `<PLUGIN>_ENABLED` variable to `true` or `false`, then restart the server with `docker compose restart`. See [CONFIG.md](CONFIG.md) for the full list of plugin toggles.

### Resetting the Server

Set `OVERWRITE_EXISTING_SERVER=true` in `.env` and restart. **This deletes all existing server data.** Reset the variable to `false` after the restart to prevent accidental data loss.

## Permissions

This project does not add any new Minecraft permission nodes itself. Permissions are managed by the individual plugins installed on the server. Refer to each plugin's documentation for details.
