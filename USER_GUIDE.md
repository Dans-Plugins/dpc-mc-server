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

This restarts the existing container without recreating it, which is what you want after editing files inside the container. It does **not** pick up changes made to `.env`, because environment variables are captured when the container is created. To apply an `.env` change, recreate the container with `./up.sh` instead.

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

Place plugin JARs or override configuration files in the `deposit-box/` directory before starting the server. The container bind-mounts this directory so that its contents are available at `/deposit-box` inside the container.

Nothing is installed automatically from the deposit box: the directory is a staging area only. To install a JAR that has been placed there, open a shell in the container and copy it across yourself, then restart:

```
docker exec -it dpc-mc-server /bin/bash
cp /deposit-box/YourPlugin.jar /dpcmcserver/plugins/
exit
docker compose restart
```

Be aware that the entrypoint script re-applies every bundled plugin toggle on each start. A JAR whose filename begins with the same prefix as a bundled plugin (for example `WildPets-`) is therefore affected by that plugin's toggle: with the toggle set to `true` the bundled copy is placed alongside it and both versions are loaded, and with the toggle set to `false` the deposited copy is deleted along with the bundled one.

### Enabling or Disabling a Plugin

Edit `.env` and set the corresponding `<PLUGIN>_ENABLED` variable to `true` or `false`, then recreate the container with `./up.sh`. See [CONFIG.md](CONFIG.md) for the full list of plugin toggles.

`docker compose restart` is not sufficient here. The toggles reach the entrypoint script through the container's environment, which is fixed when the container is created, so a restarted container still sees the old values.

### Resetting the Server

Set `OVERWRITE_EXISTING_SERVER=true` in `.env` and run `./up.sh`. **This deletes all existing server data.** Set the variable back to `false` afterwards and run `./up.sh` again to prevent accidental data loss.

Both steps require `./up.sh` rather than `docker compose restart`, for the reason given under [Restarting the Server](#restarting-the-server). Clearing the variable in `.env` and then merely restarting leaves `OVERWRITE_EXISTING_SERVER=true` in the running container's environment, which wipes the server data again on every subsequent restart.

## Permissions

This project does not add any new Minecraft permission nodes itself. Permissions are managed by the individual plugins installed on the server. Refer to each plugin's documentation for details.
