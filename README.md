# Dan's Plugins Community Minecraft Server
An infrastructure-as-code Minecraft server for the Dan's Plugins Community

Currently being hosted at [dansplugins.com](https://dansplugins.com)

## Setup
1. Install [Docker](https://docs.docker.com/get-docker/)
1. Install [Docker Compose](https://docs.docker.com/compose/install/)
1. Install [Git](https://git-scm.com/downloads)
1. Clone this repository
1. [Start the server](#starting)

## Starting
1. Run `docker compose up -d` in the repository directory
1. Type `docker ps` to confirm that the server is running

## Stopping
1. Run `docker compose down` in the repository directory
1. Type `docker ps` to confirm that the server is no longer running

## Modifying server files
1. While the server is running, run `docker exec -it dpc-mc-server /bin/bash`
2. You will now be in the server's filesystem. You can modify files as you wish.
3. When you are done, run `exit` to exit the container.
4. Run `docker compose restart` to restart the server with your changes.