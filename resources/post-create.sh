#!/bin/bash

SERVER_DIR="/dpcmcserver"
BUILD_DIR="/dpcmcserver-build"
RESOURCES_DIR="/resources/jars"

# Function: Log a message with the [POST-CREATE] prefix
log() {
    local message="$1"
    echo "[POST-CREATE] $message"
}

# Function: Setup server
setup_server() {
    if [ -z "$(ls -A "$SERVER_DIR")" ] || [ "$OVERWRITE_EXISTING_SERVER" = "true" ]; then
            rm -rf "$SERVER_DIR"/*
        cp "$BUILD_DIR"/spigot-"${MINECRAFT_VERSION}".jar "$SERVER_DIR"/spigot-"${MINECRAFT_VERSION}".jar
        mkdir "$SERVER_DIR"/plugins
    else
        log "Server is already set up."
    fi
}

# Function: Setup ops.json file
setup_ops_file() {
    log "Creating ops.json file..."
    cat <<EOF > "$SERVER_DIR"/ops.json
    [
      {
        "uuid": "${OPERATOR_UUID}",
        "name": "${OPERATOR_NAME}",
        "level": ${OPERATOR_LEVEL},
        "bypassesPlayerLimit": false
      }
    ]
EOF
}

# Function: Accept EULA
accept_eula() {
    log "Accepting Minecraft EULA..."
    echo "eula=true" > "$SERVER_DIR"/eula.txt
}

# Function: Delete lang directory
delete_lang_directory() {
    log "Deleting lang directory..."
    rm -rf "$SERVER_DIR"/plugins/MedievalFactions/lang
}

# Function: Generic plugin manager for enabling or disabling
manage_plugin_dependencies() {
    local plugin_name="$1"
    local enabled_var="$2"

    if [ "${!enabled_var}" = "true" ]; then
        log "${plugin_name} enabled. Copying plugin JAR..."
        cp "$RESOURCES_DIR"/${plugin_name}-*.jar "$SERVER_DIR"/plugins
    elif [ "${!enabled_var}" = "false" ]; then
        log "${plugin_name} disabled. Removing plugin JAR if it exists..."
        rm -f "$SERVER_DIR"/plugins/${plugin_name}-*.jar
    else
        log "Invalid value for ${enabled_var}. Must be 'true' or 'false'."
        exit
    fi
}

# Function: Update Bluemap configuration
update_bluemap_config() {
    log "Updating Bluemap configuration..."
    sed -i 's/accept-download: false/accept-download: true/g' "$SERVER_DIR"/plugins/bluemap/core.conf
}

# Function: Start server
start_server() {
    log "Starting server..."
    java -jar "$SERVER_DIR"/spigot-"${MINECRAFT_VERSION}".jar
}

# Main Process
log "Running 'post-create.sh' script..."
setup_server
setup_ops_file
accept_eula
delete_lang_directory

# Manage DPC plugins
manage_plugin_dependencies "ActivityTracker" "ACTIVITY_TRACKER_ENABLED"
manage_plugin_dependencies "AlternateAccountFinder" "ALTERNATE_ACCOUNT_FINDER_ENABLED"
manage_plugin_dependencies "currencies" "CURRENCIES_ENABLED"
manage_plugin_dependencies "Dans-Essentials" "DANS_ESSENTIALS_ENABLED"
manage_plugin_dependencies "Dans-Set-Home" "DANS_SET_HOME_ENABLED"
manage_plugin_dependencies "Dans-Spawn-System" "DANS_SPAWN_SYSTEM_ENABLED"
manage_plugin_dependencies "DansPluginManager" "DANS_PLUGIN_MANAGER_ENABLED"
manage_plugin_dependencies "Easy-Links" "EASY_LINKS_ENABLED"
manage_plugin_dependencies "Fiefs" "FIEFS_ENABLED"
manage_plugin_dependencies "FoodSpoilage" "FOOD_SPOILAGE_ENABLED"
manage_plugin_dependencies "Medieval-Economy" "MEDIEVAL_ECONOMY_ENABLED"
manage_plugin_dependencies "medieval-factions" "MEDIEVAL_FACTIONS_ENABLED"
manage_plugin_dependencies "Medieval-Roleplay-Engine" "MEDIEVAL_ROLEPLAY_ENGINE_ENABLED"
manage_plugin_dependencies "More-Recipes" "MORE_RECIPES_ENABLED"
manage_plugin_dependencies "NetherAccessController" "NETHER_ACCESS_CONTROLLER_ENABLED"
manage_plugin_dependencies "NoMoreCreepers" "NO_MORE_CREEPERS_ENABLED"
manage_plugin_dependencies "PlayerLore" "PLAYER_LORE_ENABLED"
manage_plugin_dependencies "SimpleSkills" "SIMPLE_SKILLS_ENABLED"
manage_plugin_dependencies "WildPets" "WILD_PETS_ENABLED"
manage_plugin_dependencies "ViaBackwards" "VIA_BACKWARDS_ENABLED"
manage_plugin_dependencies "ViaVersion" "VIA_VERSION_ENABLED"

# manage other plugins
if [ "$BLUEMAP_ENABLED" = "true" ]; then
    manage_plugin_dependencies "bluemap" "BLUEMAP_ENABLED"
    update_bluemap_config
fi
manage_plugin_dependencies "Dynmap" "DYNMAP_ENABLED"
manage_plugin_dependencies "PlaceholderAPI" "PLACEHOLDER_API_ENABLED"

# Start Server
start_server