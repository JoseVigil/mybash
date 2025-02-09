#!/bin/bash

# Variables
MYBASH_DIR="$HOME/mybash"

# Function to remove symbolic links
remove_symlinks() {
    echo "Removing symbolic links from /usr/local/bin..."
    rm -f /usr/local/bin/mybash
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
    read -p "Do you want to delete the mybash directory? (y/n): " choice
    if [[ "$choice" == "y" || "$choice" == "Y" ]]; then
        echo "Deleting $MYBASH_DIR..."
        rm -rf "$MYBASH_DIR"
        MYBASH_DELETED=true
    else
        echo "Skipping deletion of $MYBASH_DIR."
    fi
}

# Main logic
remove_symlinks
remove_from_zshrc
delete_mybash_dir

# Reload shell configuration only if the mybash directory was not deleted
if [[ -z "$MYBASH_DELETED" ]]; then
    echo "Reloading shell configuration..."
    source ~/.zshrc
else
    echo "Skipping shell configuration reload because mybash directory was deleted."
fi

echo "Uninstallation complete."