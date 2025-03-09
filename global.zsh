#!/bin/zsh

# Check ZSH_VERSION
[[ -z "$ZSH_VERSION" ]] && echo "Error: mybash requires ZSH_VERSION" && exit 1

# Read MYBASH_DIR and MYBASH_DATA_HOME_DIR from path.conf if it exists, otherwise use exported values
OPT_DIR="/opt/mybash"
PATH_CONF="$OPT_DIR/path.conf"
if [[ -f "$PATH_CONF" ]]; then
    MYBASH_DIR=$(grep '^MYBASH_DIR=' "$PATH_CONF" | cut -d'=' -f2)
    MYBASH_DATA_HOME_DIR=$(grep '^MYBASH_DATA_HOME_DIR=' "$PATH_CONF" | cut -d'=' -f2)
fi

################################
# SYSTEM VARIABLES = MYBASH_DIR
################################

# Define database files
DB_FILE="$MYBASH_DIR/db/mybash.db"
SCHEMA_FILE="$MYBASH_DIR/config/schema.sql"
[[ ! -f "$SCHEMA_FILE" ]] && echo "Warning: Schema file not found at $SCHEMA_FILE."

# Define dependency config locations
DEPENDENCIES_CONFIG_DIR="$MYBASH_DIR/config"
DEPENDENCIES_CONF="$DEPENDENCIES_CONFIG_DIR/dependencies.conf"
[[ ! -f "$DEPENDENCIES_CONF" ]] && echo "Warning: Dependencies config file not found at $DEPENDENCIES_CONF."

# Define system plugins config
PLUGIN_CONF="$MYBASH_DIR/config/plugins.conf"
[[ ! -f "$PLUGIN_CONF" ]] && echo "Warning: Plugins config file not found at $PLUGIN_CONF."

########################################
# USER VARIABLES = MYBASH_DATA_HOME_DIR
########################################

# Define directory structure
MYBASH_DATA_DIR="$MYBASH_DATA_HOME_DIR/workspace"
MYBASH_BACKUP_DIR="$MYBASH_DATA_HOME_DIR/backup"
MYBASH_LOGS_DIR="$MYBASH_DATA_HOME_DIR/logs"

# Define log file
LOG_FILE="$MYBASH_LOGS_DIR/mybash.log"
LOG_DIR=$MYBASH_LOGS_DIR

# Define virtual env directories
MYBASH_VENVIRONMENTS="$MYBASH_DATA_DIR/environments"
MYBASH_VENV="$MYBASH_VENVIRONMENTS/venv"
MYBASH_CONDA="$MYBASH_VENVIRONMENTS/conda"

# Define data plugins directory
PLUGINS_DIR="$MYBASH_DATA_DIR/plugins"  # Cambiado de $MYBASH_DIR/plugins
MYBASH_DATA_PLUGINS="$MYBASH_DATA_DIR/plugins"

# Define bookmark files
BKM_BOOKMARK_FILE="$MYBASH_DATA_DIR/plugins/bookmarks"
CMD_BOOKMARK_FILE="$MYBASH_DATA_DIR/plugins/commands"

# Export variables
export MYBASH_DIR MYBASH_DATA_HOME_DIR MYBASH_DATA_DIR MYBASH_BACKUP_DIR MYBASH_LOGS_DIR
export MYBASH_VENVIRONMENTS MYBASH_VENV MYBASH_CONDA
export BKM_BOOKMARK_FILE CMD_BOOKMARK_FILE LOG_DIR LOG_FILE
export DB_FILE SCHEMA_FILE DEPENDENCIES_CONFIG_DIR DEPENDENCIES_CONF PLUGINS_DIR PLUGIN_CONF MYBASH_DATA_PLUGINS