#!/bin/bash

# Logging directory and file
LOG_DIR="$HOME/Documents/mybash/log"
LOG_FILE="$LOG_DIR/mybash.log"

# Default values (fallback if .env is missing)
MYBASH_DIR="${MYBASH_DIR:-$HOME/repos/mybash}"
MYBASH_DATA_DIR="${MYBASH_DATA_DIR:-$HOME/Documents/mybash}"
LOG_DIR="$MYBASH_DATA_DIR/log"
LOG_FILE="$LOG_DIR/install.log"
CREATE_HOME_MYBASH="${CREATE_HOME_MYBASH:-false}"

# Load .env file if it exists
#ENV_FILE="$HOME/repos/mybash/.env"
#if [[ -f "$ENV_FILE" ]]; then
#    echo "Loading environment variables from $ENV_FILE..."
#    set -a  # Export all variables
#    source "$ENV_FILE"
#    set +a  # Stop exporting
#else
#    echo "Warning: .env file not found. Using default values."
#fi

# Ensure log directory exists
mkdir -p "$LOG_DIR"

# Function to log messages with metadata
log_message() {
    local message="$1"  # Message to log
    shift               # Remove the first argument
    local args="$@"     # Remaining arguments (optional)

    # Ensure log directory exists
    mkdir -p "$LOG_DIR"

    # Activate the virtual environment
    MYBASH_VENV="$HOME/Documents/mybash/venv"
    if [[ -d "$MYBASH_VENV" ]]; then
        source "$MYBASH_VENV/bin/activate"
    else
        echo "Error: Virtual environment not found at $MYBASH_VENV."
        exit 1
    fi

    # Capture metadata using Python
    local metadata
    if ! metadata=$(python3 "$MYBASH_DIR/tools/py/modules/log.py" "log_message" "$message $args" 2>&1); then
        metadata="Error capturing metadata: $metadata"
    fi

    # Deactivate the virtual environment
    deactivate

    # Log the event
    echo "$(date '+%Y-%m-%d %H:%M:%S') - Message: $message, Metadata: $metadata" >> "$LOG_FILE"
}

# Load core scripts
if [[ -f "$MYBASH_DIR/core/cmd.zsh" ]]; then
    source "$MYBASH_DIR/core/cmd.zsh"
else
    echo "Error: Core script 'cmd.zsh' not found."
    exit 1
fi

if [[ -f "$MYBASH_DIR/core/bkm.zsh" ]]; then
    source "$MYBASH_DIR/core/bkm.zsh"
else
    echo "Error: Core script 'bkm.zsh' not found."
    exit 1
fi

# Load plugins
#if [[ -f "$MYBASH_DIR/plugins/sticky_notes/main.zsh" ]]; then
#    echo "Loading sticky_notes plugin from $MYBASH_DIR/plugins/sticky_notes/main.zsh..."
#    source "$MYBASH_DIR/plugins/sticky_notes/main.zsh"
#else
#    echo "Error: Plugin script 'sticky_notes/main.zsh' not found."
#    log_message "Error: Plugin script 'sticky_notes/main.zsh' not found."
#    exit 1
#fi

# Install dependencies
install_dependencies() {
    log_message "Installing dependencies..."
    if [[ "$OSTYPE" == "darwin"* ]]; then
        # macOS
        if ! command -v brew &>/dev/null; then
            log_message "Homebrew not found. Installing Homebrew..."
            /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
        fi
        # Check and install Python@3.13
        if brew list python@3.13 &>/dev/null; then
            log_message "Python@3.13 is already installed. Skipping installation."
        else
            log_message "Installing Python@3.13..."
            brew install python@3.13
        fi
        # Check and install tree
        if brew list tree &>/dev/null; then
            log_message "Tree is already installed. Skipping installation."
        else
            log_message "Installing Tree..."
            brew install tree
        fi
        # Check and install jq
        if brew list jq &>/dev/null; then
            log_message "jq is already installed. Skipping installation."
        else
            log_message "Installing jq..."
            brew install jq
        fi
    elif [[ "$OSTYPE" == "linux-gnu"* ]]; then
        # Linux
        sudo apt update
        sudo apt install -y tree jq python3 python3-pip
    else
        log_message "Unsupported OS. Please install dependencies manually."
        return 1
    fi

    # Install Python dependencies
    log_message "Installing Python dependencies..."
    if ! pip3 install psutil &>/dev/null; then
        log_message "Error: Failed to install 'psutil'."
        echo "Error: Failed to install 'psutil'. Please check your Python environment."
        exit 1
    else
        log_message "Successfully installed 'psutil'."
        echo "Successfully installed 'psutil'."
    fi
}

# List and check dependencies
list_dependencies() {
    log_message "Checking system dependencies..."
    echo "Checking system dependencies..."

    # Define required dependencies
    declare -A DEPENDENCIES=(
        ["tree"]="Tree utility for directory visualization"
        ["jq"]="Command-line JSON processor"
        ["python3"]="Python 3.x (required for scripts)"
        ["pip3"]="Python package manager"
        ["psutil"]="Python module for process and system monitoring"
    )

    # Check each dependency
    for dep in "${!DEPENDENCIES[@]}"; do
        description="${DEPENDENCIES[$dep]}"
        case "$dep" in
            psutil)
                if python3 -c "import psutil" &>/dev/null; then
                    echo "✅ $dep: Installed ($description)"
                    log_message "Dependency '$dep' is installed."
                else
                    echo "❌ $dep: Not installed ($description)"
                    log_message "Dependency '$dep' is NOT installed."
                fi
                ;;
            *)
                if command -v "$dep" &>/dev/null; then
                    echo "✅ $dep: Installed ($description)"
                    log_message "Dependency '$dep' is installed."
                else
                    echo "❌ $dep: Not installed ($description)"
                    log_message "Dependency '$dep' is NOT installed."
                fi
                ;;
        esac
    done

    echo "Dependency check complete."
    log_message "Dependency check complete."
}

# Create symbolic links
create_symlinks() {
    log_message "Creating symbolic links in /usr/local/bin..."
    if [[ -f "$MYBASH_DIR/mybash.zsh" ]]; then
        ln -sf "$MYBASH_DIR/mybash.zsh" /usr/local/bin/mybash
        log_message "Created symlink for mybash.zsh."
    else
        log_message "Error: mybash.zsh not found in $MYBASH_DIR."
        exit 1
    fi
    if [[ -f "$MYBASH_DIR/tools/mypy.zsh" ]]; then
        ln -sf "$MYBASH_DIR/tools/mypy.zsh" /usr/local/bin/mypy
        log_message "Created symlink for mypy.zsh."
    else
        log_message "Warning: mypy.zsh not found in $MYBASH_DIR/tools. Skipping symlink creation."
    fi
}

# Add mybash.zsh to ~/.zshrc
add_to_zshrc() {
    log_message "Adding mybash.zsh to ~/.zshrc..."
    if [[ -f "$MYBASH_DIR/mybash.zsh" ]]; then
        if ! grep -q "source $MYBASH_DIR/mybash.zsh" ~/.zshrc; then
            echo "source $MYBASH_DIR/mybash.zsh" >> ~/.zshrc
            log_message "Added mybash.zsh to ~/.zshrc."
        else
            log_message "mybash.zsh is already in ~/.zshrc."
        fi
    else
        log_message "Error: mybash.zsh not found in $MYBASH_DIR."
        exit 1
    fi
}

# Create data directories
create_data_directories() {
    log_message "Creating data directories in $MYBASH_DATA_DIR..."
    mkdir -p "$MYBASH_DATA_DIR/log"
    mkdir -p "$MYBASH_DATA_DIR/migrate/import"
    mkdir -p "$MYBASH_DATA_DIR/migrate/export"
    mkdir -p "$MYBASH_DATA_DIR/adapters/stickies"
    log_message "Data directories created successfully."
}

# Backup command
mybash_backup() {
    BACKUP_DIR="$MYBASH_DATA_DIR/backup"
    TIMESTAMP=$(date '+%Y%m%d%H%M%S')
    BACKUP_PATH="$BACKUP_DIR/mybash-backup-$TIMESTAMP"
    # Ensure the backup directory exists
    mkdir -p "$BACKUP_PATH"
    # Copy the entire mybash repository to the backup location
    echo "Creating backup of $MYBASH_DIR in $BACKUP_PATH..."
    if cp -r "$MYBASH_DIR"/* "$BACKUP_PATH"; then
        echo "Backup created successfully: $BACKUP_PATH"
        log_message "Backup created successfully: $BACKUP_PATH"
    else
        echo "Error: Backup failed."
        log_message "Error: Backup failed."
        return 1
    fi
}

# Help command
show_help() {
    echo "Usage: mybash [command]"
    echo ""
    echo "Available commands:"
    echo "  help         Show this help message"
    echo "  backup       Create a backup of the mybash project"
    echo "  dependencies Install required dependencies"
    echo "  symlinks     Create symbolic links"
    echo "  zshrc        Add mybash.zsh to ~/.zshrc"
    echo "  data         Create data directories"
    echo "  test         Run automated tests"
    echo "  cmd          Execute cmd commands"
    echo "  bkm          Execute bkm commands"
    echo "  sticky       Manage sticky notes"
}

# Run tests command
run_tests() {
    TEST_SCRIPT="$MYBASH_DIR/utils/test.zsh"
    if [[ -f "$TEST_SCRIPT" ]]; then
        echo "Running tests..."
        bash "$TEST_SCRIPT"
    else
        echo "Error: Test script not found at $TEST_SCRIPT."
        log_message "Error: Test script not found at $TEST_SCRIPT."
        exit 1
    fi
}

# Main logic
case "$1" in
    help)
        show_help
        ;;
    backup)
        mybash_backup
        ;;
    dependencies)
        list_dependencies
        ;;
    symlinks)
        create_symlinks
        ;;
    zshrc)
        add_to_zshrc
        ;;
    data)
        create_data_directories
        ;;
    test)
        run_tests
        ;;
    cmd)
        cmd_main "$@"
        ;;
    bkm)
        bkm_main "$@"
        ;;
    sticky)
        echo "Processing 'sticky' command..."
        # Shift to remove the first argument ('sticky')
        shift

        if declare -F sticky_main &>/dev/null; then
            echo "'sticky_main' function found. Calling it with arguments: $@"
            sticky_main "$@"
        else
            echo "Error: 'sticky_main' function not found. Ensure the sticky_notes plugin is loaded."
            log_message "Error: 'sticky_main' function not found."
            exit 1
        fi
        ;;
    *)
        echo "Unknown command: $1"
        show_help
        exit 1
        ;;
esac