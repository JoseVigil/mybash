#!/bin/bash

# Variables
MYBASH_DIR="$HOME/repos/mybash"
MYBASH_DATA_DIR="$HOME/Documents/mybash"
LOG_DIR="$MYBASH_DATA_DIR/log"
LOG_FILE="$LOG_DIR/install.log"

# Function to log messages
log_message() {
    mkdir -p "$LOG_DIR"  # Ensure the log directory exists
    echo "$(date '+%Y-%m-%d %H:%M:%S') - $1" >> "$LOG_FILE"
}

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
        sudo apt install -y tree jq python3
    else
        log_message "Unsupported OS. Please install dependencies manually."
        return 1
    fi
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

# Main logic
case "$1" in
    dependencies)
        install_dependencies
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
    *)
        install_dependencies
        create_symlinks
        add_to_zshrc
        create_data_directories
        log_message "Installation complete. Please open a new terminal to apply changes."
        echo "Installation complete. Please check the log file at $LOG_FILE for details."
        ;;
esac