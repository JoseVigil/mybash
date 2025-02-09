#!/bin/bash

# Variables
MYBASH_DIR="$HOME/mybash"

# Function to install dependencies
install_dependencies() {
    echo "Installing dependencies..."
    if [[ "$OSTYPE" == "darwin"* ]]; then
        # macOS
        if ! command -v brew &>/dev/null; then
            echo "Homebrew not found. Installing Homebrew..."
            /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
        fi
        brew install tree jq python3
    elif [[ "$OSTYPE" == "linux-gnu"* ]]; then
        # Linux
        sudo apt update
        sudo apt install -y tree jq python3
    else
        echo "Unsupported OS. Please install dependencies manually."
        return 1
    fi
}

# Function to create symbolic links
create_symlinks() {
    echo "Creating symbolic links in /usr/local/bin..."
    if [[ ! -f "$MYBASH_DIR/mybash.zsh" ]]; then
        echo "Error: mybash.zsh not found in $MYBASH_DIR. Please ensure the file exists before creating the symlink."
        return 1
    fi
    ln -sf "$MYBASH_DIR/mybash.zsh" /usr/local/bin/mybash
}

# Function to add mybash.zsh to ~/.zshrc
add_to_zshrc() {
    echo "Adding mybash.zsh to ~/.zshrc..."
    if ! grep -q "source $MYBASH_DIR/mybash.zsh" ~/.zshrc; then
        echo "source $MYBASH_DIR/mybash.zsh" >> ~/.zshrc
    else
        echo "mybash.zsh is already in ~/.zshrc."
    fi
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
    *)
        install_dependencies
        create_symlinks
        add_to_zshrc
        echo "Installation complete. Please open a new terminal to apply changes."
        ;;
esac