#!/bin/bash

# Variables
MYBASH_DIR="$HOME/repos/mybash"
MYBASH_DATA_DIR="$HOME/Documents/mybash"

# Function to remove symbolic links
remove_symlinks() {
    echo "Removing symbolic links from /usr/local/bin..."
    rm -f /usr/local/bin/mybash
    rm -f /usr/local/bin/mypy
}

# Function to remove mybash.zsh from ~/.zshrc
remove_from_zshrc() {
    echo "Removing mybash.zsh from ~/.zshrc..."
    if grep -q "source $MYBASH_DIR/mybash.zsh" ~/.zshrc; then
        sed -i.bak '/source \$MYBASH_DIR\/mybash.zsh/d' ~/.zshrc
        echo "Removed mybash.zsh from ~/.zshrc."
    else
        echo "mybash.zsh is not in ~/.zshrc."
    fi
}

# Function to optionally delete the mybash directory
delete_mybash_dir() {
    read -p "Do you want to delete the mybash directory ($MYBASH_DIR)? (y/n): " choice
    if [[ "$choice" == "y" || "$choice" == "Y" ]]; then
        echo "Deleting $MYBASH_DIR..."
        rm -rf "$MYBASH_DIR"
        MYBASH_DELETED=true
    else
        echo "Skipping deletion of $MYBASH_DIR."
    fi
}

# Function to delete the mybash data directory
delete_mybash_data_dir() {
    read -p "Do you want to delete the mybash data directory ($MYBASH_DATA_DIR)? (y/n): " choice
    if [[ "$choice" == "y" || "$choice" == "Y" ]]; then
        echo "Deleting $MYBASH_DATA_DIR..."
        rm -rf "$MYBASH_DATA_DIR"
        MYBASH_DATA_DELETED=true
    else
        echo "Skipping deletion of $MYBASH_DATA_DIR."
    fi
}

# Main logic
remove_symlinks
remove_from_zshrc
delete_mybash_dir
delete_mybash_data_dir

echo "Uninstallation complete."