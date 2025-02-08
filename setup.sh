#!/bin/zsh

# Define the mybash directory
MYBASH_DIR=~/mybash

# Function to check and install dependencies
install_dependencies() {
    echo "Checking and installing dependencies..."

    # Check for jq
    if ! command -v jq &> /dev/null; then
        echo "jq is not installed. Installing jq..."
        if [[ "$OSTYPE" == "darwin"* ]]; then
            # macOS: Use Homebrew
            if ! command -v brew &> /dev/null; then
                echo "Homebrew is not installed. Please install Homebrew first: https://brew.sh"
                exit 1
            fi
            brew install jq
        elif [[ "$OSTYPE" == "linux-gnu"* ]]; then
            # Linux: Use apt or yum
            if command -v apt &> /dev/null; then
                sudo apt update
                sudo apt install -y jq
            elif command -v yum &> /dev/null; then
                sudo yum install -y jq
            else
                echo "Unable to determine package manager. Please install jq manually."
                exit 1
            fi
        else
            echo "Unsupported OS. Please install jq manually."
            exit 1
        fi
    else
        echo "jq is already installed."
    fi
}

# Create symbolic links in /usr/local/bin
echo "Creating symbolic links in /usr/local/bin..."
ln -sf "$MYBASH_DIR/bookmark" /usr/local/bin/bookmark
ln -sf "$MYBASH_DIR/cmd" /usr/local/bin/cmd
ln -sf "$MYBASH_DIR/mybash" /usr/local/bin/mybash

# Ensure mybash.zsh is sourced in ~/.zshrc
echo "Adding mybash.zsh to ~/.zshrc..."
if ! grep -q "source $MYBASH_DIR/mybash.zsh" ~/.zshrc; then
    echo "source $MYBASH_DIR/mybash.zsh" >> ~/.zshrc
fi

# Add the 'mb' alias to ~/.zshrc
echo "Adding 'mb' alias to ~/.zshrc..."
if ! grep -q "alias mb='mybash'" ~/.zshrc; then
    echo "alias mb='mybash'" >> ~/.zshrc
fi

# Install dependencies
install_dependencies

# Reload the shell
echo "Reloading shell configuration..."
source ~/.zshrc

echo "Setup complete! You can now use 'mybash --help' or 'mb --help'."