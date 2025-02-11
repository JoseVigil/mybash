#!/bin/bash

# Function to log messages
log_message() {
    mkdir -p "$LOG_DIR"  # Ensure the log directory exists
    echo "$(date '+%Y-%m-%d %H:%M:%S') - $1" >> "$LOG_FILE"
}

# Variables
MYBASH_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
MYBASH_DATA_DIR="$HOME/Documents/mybash"
LOG_DIR="$MYBASH_DATA_DIR/log"
LOG_FILE="$LOG_DIR/install.log"

# Optional: Create $HOME/mybash if needed
CREATE_HOME_MYBASH=false  # Default is false (development mode)
if [[ "$1" == "--prod" ]]; then
    CREATE_HOME_MYBASH=true
fi

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

    # Install psutil in a virtual environment
    log_message "Setting up Python virtual environment for mybash..."
    MYBASH_VENV="$MYBASH_DATA_DIR/venv"
    if [[ ! -d "$MYBASH_VENV" ]]; then
        log_message "Creating virtual environment at $MYBASH_VENV..."
        python3 -m venv "$MYBASH_VENV"
    fi

    # Activate the virtual environment
    source "$MYBASH_VENV/bin/activate"

    # Upgrade pip to avoid issues
    log_message "Upgrading pip in the virtual environment..."
    pip install --upgrade pip

    # Install psutil
    log_message "Installing psutil in the virtual environment..."
    if ! pip install psutil; then
        log_message "Error: Failed to install 'psutil'."
        echo "Error: Failed to install 'psutil'. Check the output above for details."
        exit 1
    else
        log_message "Successfully installed 'psutil'."
        echo "Successfully installed 'psutil'."
    fi

    # Deactivate the virtual environment
    deactivate
}

# Copy files to $HOME/mybash for production mode
copy_to_home_mybash() {
    HOME_MYBASH_DIR="$HOME/mybash"
    mkdir -p "$HOME_MYBASH_DIR"
    log_message "Copying files to $HOME_MYBASH_DIR..."
    cp -r "$MYBASH_DIR/core" "$HOME_MYBASH_DIR/" 2>/dev/null || true
    cp -r "$MYBASH_DIR/db" "$HOME_MYBASH_DIR/" 2>/dev/null || true
    cp -r "$MYBASH_DIR/plugins" "$HOME_MYBASH_DIR/" 2>/dev/null || true
    cp -r "$MYBASH_DIR/tools" "$HOME_MYBASH_DIR/" 2>/dev/null || true
    cp -r "$MYBASH_DIR/utils" "$HOME_MYBASH_DIR/" 2>/dev/null || true
    cp "$MYBASH_DIR/mybash.zsh" "$HOME_MYBASH_DIR/" 2>/dev/null || true
    cp "$MYBASH_DIR/version" "$HOME_MYBASH_DIR/" 2>/dev/null || true
    log_message "Files copied successfully to $HOME_MYBASH_DIR."
}

# Create data directories
create_data_directories() {
    log_message "Creating data directories in $MYBASH_DATA_DIR..."
    mkdir -p "$MYBASH_DATA_DIR/adapters/stickies"
    mkdir -p "$MYBASH_DATA_DIR/log"
    mkdir -p "$MYBASH_DATA_DIR/migrate/import"
    mkdir -p "$MYBASH_DATA_DIR/migrate/export"
    log_message "Data directories created successfully."
}

# Add mybash.zsh to ~/.zshrc
add_to_zshrc() {
    log_message "Checking for mybash.zsh in $MYBASH_DIR..."
    if [[ "$CREATE_HOME_MYBASH" == true ]]; then
        MYBASH_DIR="$HOME/mybash"
    fi
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

# Main logic
case "$1" in
    --prod)
        CREATE_HOME_MYBASH=true
        copy_to_home_mybash
        install_dependencies
        create_data_directories
        add_to_zshrc
        log_message "Production installation complete. Please open a new terminal to apply changes."
        echo "Production installation complete. Please check the log file at $LOG_FILE for details."
        ;;
    --dev)
        CREATE_HOME_MYBASH=false
        install_dependencies
        create_data_directories
        add_to_zshrc
        log_message "Development installation complete. Please open a new terminal to apply changes."
        echo "Development installation complete. Please check the log file at $LOG_FILE for details."
        ;;
    *)
        echo "Usage: bash install.sh [--prod | --dev]"
        echo "  --prod   Install for production (files copied to \$HOME/mybash)"
        echo "  --dev    Install for development (use repository directly)"
        exit 1
        ;;
esac