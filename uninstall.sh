#!/bin/zsh

# Define the mybash directory
MYBASH_DIR=~/mybash

# Remove symbolic links from /usr/local/bin
echo "Removing symbolic links from /usr/local/bin..."
rm -f /usr/local/bin/bookmark
rm -f /usr/local/bin/cmd
rm -f /usr/local/bin/mybash

# Remove mybash.zsh from ~/.zshrc
echo "Removing mybash.zsh from ~/.zshrc..."
sed -i '' '/source $MYBASH_DIR\/mybash.zsh/d' ~/.zshrc

# Reload the shell
echo "Reloading shell configuration..."
source ~/.zshrc

echo "Uninstall complete! MyBash utilities have been removed."
