# Commands Reference

DPC MC Server is a server infrastructure project, not a Minecraft plugin, and therefore does not add its own in-game commands. Refer to each installed plugin's documentation for the commands it provides.

The management commands below are used to operate the server from the host machine.

## Docker Management Commands

### Start the server

**Description:** Build the Docker image (if necessary) and start the server in the background.  
**Usage:** `./up.sh`

### Stop the server

**Description:** Stop and remove the running server container.  
**Usage:** `./down.sh`

### Restart the server

**Description:** Restart the running container without rebuilding the image.  
**Usage:** `docker compose restart`

### View server logs

**Description:** Stream the server console output to your terminal.  
**Usage:** `docker logs -f dpc-mc-server`

### Open a shell inside the container

**Description:** Attach an interactive Bash session to the running container so you can inspect or modify server files.  
**Usage:** `docker exec -it dpc-mc-server /bin/bash`

### Rebuild the image

**Description:** Rebuild the Docker image from scratch (e.g. after changing `Dockerfile` or updating plugin JARs).  
**Usage:** `docker build -t dpc-mc-server .`

## Plugin Commands

Each installed plugin provides its own set of in-game commands. Links to their individual command references are listed below:

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
