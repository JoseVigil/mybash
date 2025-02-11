#!/bin/bash

# Function to log messages
log_message() {
    echo "$(date '+%Y-%m-%d %H:%M:%S') - $1"
}

# Check if the plugin name is provided
if [[ -z "$1" ]]; then
    echo "Usage: create_plugin.sh <plugin_name> [type]"
    echo "  type: 'main' for main plugins, 'sub' for sub-plugins (default: main)"
    exit 1
fi

PLUGIN_NAME="$1"
PLUGIN_TYPE="${2:-main}" # Default to 'main' if no type is specified
PLUGINS_DIR="$PWD"       # Root directory for plugins
PLUGIN_DIR="$PLUGINS_DIR/$PLUGIN_NAME"

# Check if the plugin directory already exists
if [[ -d "$PLUGIN_DIR" ]]; then
    echo "Error: Directory '$PLUGIN_DIR' already exists."
    exit 1
fi

echo "Creating plugin '$PLUGIN_NAME' in $PLUGIN_DIR..."

# Step 1: Create the plugin directory structure
mkdir -p "$PLUGIN_DIR/scripts"
mkdir -p "$PLUGIN_DIR/templates"

# Step 2: Create main.zsh
cat <<EOF > "$PLUGIN_DIR/main.zsh"
# plugins/$PLUGIN_NAME/main.zsh

# Source helper functions
source "\$MYBASH_DIR/plugins/$PLUGIN_NAME/helper.zsh"

# Main function for the plugin
${PLUGIN_NAME}_main() {
    local action="\$1"
    shift

    case "\$action" in
        help)
            echo "Usage: mybash $PLUGIN_NAME <action> [options]"
            echo "Actions:"
            echo "  help     Show this help message."
            ;;
        *)
            echo "Unknown action: \$action"
            echo "Run 'mybash $PLUGIN_NAME help' for usage information."
            ;;
    esac
}
EOF

# Step 3: Create helper.zsh
cat <<EOF > "$PLUGIN_DIR/helper.zsh"
# plugins/$PLUGIN_NAME/helper.zsh

# Path to Python scripts
SCRIPTS_DIR="\$MYBASH_DIR/plugins/$PLUGIN_NAME/scripts"

# Function to run Python scripts
run_python_script() {
    local script_name="\$1"
    shift
    python3 "\$SCRIPTS_DIR/\$script_name" "\$@"
}

# Error handling
handle_error() {
    echo "Error: \$1"
    log_message "Error: \$1"
    exit 1
}
EOF

# Step 4: Create requirements.txt
cat <<EOF > "$PLUGIN_DIR/requirements.txt"
# Add Python dependencies here
EOF

# Step 5: Create README.md
cat <<EOF > "$PLUGIN_DIR/README.md"
# Plugin: $PLUGIN_NAME

## Description
This is a template plugin for mybash. Customize it to add your own functionality.

## Structure
- **main.zsh**: Main entry point for the plugin.
- **helper.zsh**: Helper functions for the plugin.
- **requirements.txt**: Python dependencies.
- **scripts/**: Python scripts for specific tasks.
- **templates/**: Templates or configuration files.

## Usage
1. Install the plugin using \`mybash install plugin /path/to/$PLUGIN_NAME\`.
2. Use the plugin with \`mybash $PLUGIN_NAME <action>\`.

## Example
\`\`\`
mybash $PLUGIN_NAME help
\`\`\`
EOF

# Step 6: Log success
log_message "Plugin '$PLUGIN_NAME' created successfully at $PLUGIN_DIR."

echo "Plugin '$PLUGIN_NAME' created successfully."
echo "Next steps:"
echo "1. Add your custom logic to main.zsh and helper.zsh."
echo "2. Add Python scripts to the 'scripts/' folder."
echo "3. Install the plugin using 'mybash install plugin $PLUGIN_DIR'."
