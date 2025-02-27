#!/bin/zsh

# Check ZSH_VERSION
[[ -z "$ZSH_VERSION" ]] && echo "Error: mybash requires ZSH_VERSION" && exit 1

# Set MYBASH_DIR to the directory containing this script
THIS_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Read MYBASH_DIR and MYBASH_DATA_HOME_DIR from path.conf if it exists, otherwise use exported values
OPT_DIR="/opt/mybash"
PATH_CONF="$OPT_DIR/path.conf"
if [[ -f "$PATH_CONF" ]]; then
    MYBASH_DIR=$(grep '^MYBASH_DIR=' "$PATH_CONF" | cut -d'=' -f2)
    MYBASH_DATA_HOME_DIR=$(grep '^MYBASH_DATA_HOME_DIR=' "$PATH_CONF" | cut -d'=' -f2)
fi

# Use exported MYBASH_DATA_HOME_DIR if set, otherwise default to user's home
MYBASH_DIR="${MYBASH_DIR:-$THIS_DIR}"
MYBASH_DATA_HOME_DIR="${MYBASH_DATA_HOME_DIR:-/Users/$USER/mybash}"  # Use $USER instead of $SUDO_USER

# Define directory structure
MYBASH_DATA_DIR="$MYBASH_DATA_HOME_DIR/workspace"
MYBASH_BACKUP_DIR="$MYBASH_DATA_HOME_DIR/backup"
MYBASH_LOGS_DIR="$MYBASH_DATA_HOME_DIR/logs"

# Define virtual env directories
MYBASH_VENVIRONMENTS="$MYBASH_DATA_DIR/environments"
MYBASH_VENV="$MYBASH_VENVIRONMENTS/venv"
MYBASH_CONDA="$MYBASH_VENVIRONMENTS/conda"

# Define bookmark files
BKM_BOOKMARK_FILE="$MYBASH_DATA_DIR/plugins/bookmarks"
CMD_BOOKMARK_FILE="$MYBASH_DATA_DIR/plugins/commands"

# Define log file
LOG_DIR="$MYBASH_DATA_HOME_DIR/logs"
LOG_FILE="$LOG_DIR/mybash.log"

# Define database files
DB_FILE="$MYBASH_DIR/db/mybash.db"
SCHEMA_FILE="$MYBASH_DIR/config/schema.sql"
if [[ ! -f "$SCHEMA_FILE" ]]; then
    echo "Error: Schema file not found at $SCHEMA_FILE."
    exit 1
fi

# Define dependency config locations
DEPENDENCIES_CONFIG_DIR="$MYBASH_DIR/config"
DEPENDENCIES_CONF="$DEPENDENCIES_CONFIG_DIR/dependencies.conf"
if [[ ! -f "$DEPENDENCIES_CONF" ]]; then
    echo "Error: Dependencies config file not found at $DEPENDENCIES_CONF."
    exit 1
fi

# Define plugins directory and config
PLUGINS_DIR="$MYBASH_DIR/plugins"
PLUGIN_CONF="$MYBASH_DIR/config/plugins.conf"
if [[ ! -f "$PLUGIN_CONF" ]]; then
    echo "Error: Plugins config file not found at $PLUGIN_CONF."
    exit 1
fi

# Export variables
export MYBASH_DIR MYBASH_DATA_HOME_DIR MYBASH_DATA_DIR MYBASH_BACKUP_DIR MYBASH_LOGS_DIR
export MYBASH_VENVIRONMENTS MYBASH_VENV MYBASH_CONDA
export BKM_BOOKMARK_FILE CMD_BOOKMARK_FILE LOG_DIR LOG_FILE
export DB_FILE SCHEMA_FILE DEPENDENCIES_CONFIG_DIR DEPENDENCIES_CONF PLUGINS_DIR PLUGIN_CONF