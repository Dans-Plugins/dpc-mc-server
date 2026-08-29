# Configuration Guide

All configuration is done through environment variables. Copy `sample.env` to `.env` and edit the values before starting the server. The variables are listed below in the same order they appear in `sample.env`.

## MINECRAFT_VERSION

**Type:** string  
**Default:** `1.21.4`  
**Description:** Names the Spigot JAR that the container copies into the server directory and launches at startup (`spigot-<MINECRAFT_VERSION>.jar`). The value is read at runtime by `resources/post-create.sh`; it is **not** read by BuildTools. The Spigot revision that is compiled into the image is set separately, by the hardcoded `--rev` argument in the `Dockerfile`.

**Changing the Minecraft version therefore requires editing two places:** this variable *and* the `--rev` argument in the `Dockerfile`. If the two disagree, the image still builds successfully and the container then exits at startup, because the JAR it has been told to launch was never produced.

**Example:**

```env
MINECRAFT_VERSION=1.21.4
```

## OPERATOR_UUID

**Type:** string (UUID)  
**Default:** `0a9fa342-3139-49d7-8acb-fcf4d9c1f0ef`  
**Description:** The UUID of the player who should be granted operator status on first run. Obtain your UUID from a service such as [mcuuid.net](https://mcuuid.net/).

**Example:**

```env
OPERATOR_UUID=0a9fa342-3139-49d7-8acb-fcf4d9c1f0ef
```

## OPERATOR_NAME

**Type:** string  
**Default:** `DanTheTechMan`  
**Description:** The Minecraft username of the operator. Must match the account associated with `OPERATOR_UUID`.

**Example:**

```env
OPERATOR_NAME=YourUsername
```

## OPERATOR_LEVEL

**Type:** integer (1–4)  
**Default:** `4`  
**Description:** The operator permission level. Level 4 grants the highest level of operator privileges. See the [Minecraft wiki](https://minecraft.wiki/w/Permission_level) for details.

**Example:**

```env
OPERATOR_LEVEL=4
```

## OVERWRITE_EXISTING_SERVER

**Type:** boolean (`true` / `false`)  
**Default:** `false`  
**Description:** When `true`, all existing server data is deleted and the server is re-initialised on the next container start. **Use with caution** – this is destructive. Reset to `false` immediately after the reset to avoid accidental data loss.

Note that the value is captured in the container's environment when the container is created. Setting it back to `false` and then running `docker compose restart` does **not** clear it: the old value is still in the running container's environment, and the server data is wiped again on every restart. The container must be recreated with `./up.sh` for the new value to take effect.

**Example:**

```env
OVERWRITE_EXISTING_SERVER=false
```

---

## DPC Plugin Toggles

Each of the following variables accepts `true` (install and enable the plugin) or `false` (remove the plugin's JAR if it is already installed, and do not install it). Set them in `.env` before starting the server. Because the toggles are read from the container's environment by the entrypoint script, an edit made after the container already exists only takes effect once the container has been recreated with `./up.sh` – see [Enabling or Disabling a Plugin](USER_GUIDE.md#enabling-or-disabling-a-plugin).

Any other value – including an empty value or a typo such as `ture` – is a fatal error. The entrypoint logs `Invalid value for <VARIABLE>. Must be 'true' or 'false'.` and exits with status `1` before the server is started, so the container stops and `docker logs dpc-mc-server` shows the offending variable. The same rule applies to the third-party toggles below.

| Variable | Default | Plugin |
|----------|---------|--------|
| `ACTIVITY_TRACKER_ENABLED` | `true` | [ActivityTracker](https://github.com/Dans-Plugins/ActivityTracker) |
| `ALTERNATE_ACCOUNT_FINDER_ENABLED` | `true` | [AlternateAccountFinder](https://github.com/Dans-Plugins/AlternateAccountFinder) |
| `CURRENCIES_ENABLED` | `true` | [Currencies](https://github.com/Dans-Plugins/Currencies) |
| `DANS_ESSENTIALS_ENABLED` | `true` | [Dans-Essentials](https://github.com/Dans-Plugins/Dans-Essentials) |
| `DANS_SET_HOME_ENABLED` | `true` | [Dans-Set-Home](https://github.com/Dans-Plugins/Dans-Set-Home) |
| `DANS_SPAWN_SYSTEM_ENABLED` | `true` | [Dans-Spawn-System](https://github.com/Dans-Plugins/Dans-Spawn-System) |
| `FIEFS_ENABLED` | `false` | [Fiefs](https://github.com/Dans-Plugins/Fiefs) |
| `FOOD_SPOILAGE_ENABLED` | `true` | [FoodSpoilage](https://github.com/Dans-Plugins/FoodSpoilage) |
| `MAILBOXES_ENABLED` | `true` | [Mailboxes](https://github.com/Dans-Plugins/Mailboxes) |
| `MEDIEVAL_ECONOMY_ENABLED` | `false` | [Medieval-Economy](https://github.com/Dans-Plugins/Medieval-Economy) |
| `MEDIEVAL_FACTIONS_ENABLED` | `true` | [Medieval-Factions](https://github.com/Dans-Plugins/Medieval-Factions) |
| `MEDIEVAL_ROLEPLAY_ENGINE_ENABLED` | `true` | [Medieval-Roleplay-Engine](https://github.com/Dans-Plugins/Medieval-Roleplay-Engine) |
| `MORE_RECIPES_ENABLED` | `true` | [More-Recipes](https://github.com/Dans-Plugins/More-Recipes) |
| `NETHER_ACCESS_CONTROLLER_ENABLED` | `true` | [NetherAccessController](https://github.com/Dans-Plugins/NetherAccessController) |
| `NO_MORE_CREEPERS_ENABLED` | `true` | [NoMoreCreepers](https://github.com/Dans-Plugins/NoMoreCreepers) |
| `PLAYER_LORE_ENABLED` | `true` | [PlayerLore](https://github.com/Dans-Plugins/PlayerLore) |
| `SIMPLE_SKILLS_ENABLED` | `true` | [SimpleSkills](https://github.com/Dans-Plugins/SimpleSkills) |
| `WILD_PETS_ENABLED` | `true` | [WildPets](https://github.com/Dans-Plugins/WildPets) |

---

## Third-Party Plugin Toggles

| Variable | Default | Plugin |
|----------|---------|--------|
| `BLUEMAP_ENABLED` | `false` | [BlueMap](https://bluemap.bluecolored.de/) |
| `DYNMAP_ENABLED` | `true` | [Dynmap](https://www.spigotmc.org/resources/dynmap.274/) |
| `PLACEHOLDER_API_ENABLED` | `true` | [PlaceholderAPI](https://www.spigotmc.org/resources/placeholderapi.6245/) |
| `VIA_BACKWARDS_ENABLED` | `true` | [ViaBackwards](https://www.spigotmc.org/resources/viabackwards.27448/) |
| `VIA_VERSION_ENABLED` | `true` | [ViaVersion](https://www.spigotmc.org/resources/viaversion.19254/) |
