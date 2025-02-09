# mybash.zsh

# Load environment variables from .env file
if [[ -f "$MYBASH_DIR/.env" ]]; then
    export $(grep -v '^#' "$MYBASH_DIR/.env" | xargs)
fi

# Default values if not set in .env
MYBASH_ENV=${MYBASH_ENV:-"production"}
MYBASH_DIR=${MYBASH_DIR:-"$HOME/mybash"}
MYBASH_VERSION=${MYBASH_VERSION:-"1.0.0"}

echo "Running in $MYBASH_ENV mode"
echo "MyBash Directory: $MYBASH_DIR"
echo "Version: $MYBASH_VERSION"

# Load core functionality
core_init() {
    echo "Initializing MyBash Core..."
    source "$MYBASH_DIR/core/utils.zsh"
    source "$MYBASH_DIR/core/bkm.zsh"
    source "$MYBASH_DIR/core/cmd.zsh"
    source "$MYBASH_DIR/core/synch.zsh"
}

# Load plugins dynamically
load_plugins() {
    if [[ -d "$MYBASH_DIR/plugins" ]]; then
        for plugin in "$MYBASH_DIR/plugins"/*.zsh; do
            if [[ -f "$plugin" ]]; then
                echo "Loading plugin: $plugin"
                source "$plugin"
            fi
        done
    else
        echo "No plugins directory found."
    fi
}

# Load tools dynamically
load_tools() {
    if [[ -d "$MYBASH_DIR/tools" ]]; then
        for tool in "$MYBASH_DIR/tools"/*.zsh; do
            if [[ -f "$tool" ]]; then
                echo "Loading tool: $tool"
                source "$tool"
            fi
        done
    else
        echo "No tools directory found."
    fi
}

# Load utilities
load_utils() {
    if [[ -f "$MYBASH_DIR/utils/utils.zsh" ]]; then
        echo "Loading utility: $MYBASH_DIR/utils/utils.zsh"
        source "$MYBASH_DIR/utils/utils.zsh"
    else
        echo "No general utilities found."
    fi
    if [[ -f "$MYBASH_DIR/utils/views.zsh" ]]; then
        echo "Loading views: $MYBASH_DIR/utils/views.zsh"
        source "$MYBASH_DIR/utils/views.zsh"
    else
        echo "No view utilities found."
    fi
}

# Initialize MyBash
core_init
load_plugins
load_tools
load_utils

# Function to display general help
display_help() {
    echo "Usage: mybash <command> [options]"
    echo "Available commands:"
    echo "  bkm      Manage bookmarks (add, list, remove)."
    echo "  cmd      Manage custom commands (add, list, remove)."
    echo "  help     Show this help message."
    echo ""
    echo "Examples:"
    echo "  mybash bkm add my_project ~/Projects/my_project"
    echo "  mybash cmd add gs 'git status'"
    echo "  mybash help"
}

# Main logic for the master interpreter
if [[ $# -eq 0 ]]; then
    display_help
    exit 0
fi

case "$1" in
    bkm)
        shift
        bkm "$@"
        ;;
    cmd)
        shift
        cmd "$@"
        ;;
    help)
        display_help
        ;;
    *)
        echo "Unknown command: $1"
        echo "Run 'mybash help' for usage information."
        ;;
esac