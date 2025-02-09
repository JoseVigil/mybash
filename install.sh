#!/bin/zsh

# Define the mybash directory
MYBASH_DIR="\$HOME/mybash"

# Function to check and install dependencies
install_dependencies() {
    echo "Checking and installing dependencies..."
    if ! command -v jq &> /dev/null; then
        echo "jq is not installed. Installing jq..."
        if [[ "\$OSTYPE" == "darwin"* ]]; then
            brew install jq
        elif [[ "\$OSTYPE" == "linux-gnu"* ]]; then
            sudo apt update && sudo apt install -y jq
        else
            echo "Unsupported OS. Please install jq manually."
            exit 1
        fi
    fi
}

# Function to create symbolic links
create_symlinks() {
    echo "Creating symbolic links in /usr/local/bin..."
    ln -sf "\$MYBASH_DIR/mybash" /usr/local/bin/mybash
}

# Function to add mybash.zsh to ~/.zshrc
add_to_zshrc() {
    echo "Adding mybash.zsh to ~/.zshrc..."
    if ! grep -q "source \$MYBASH_DIR/mybash.zsh" ~/.zshrc; then
        echo "source \$MYBASH_DIR/mybash.zsh" >> ~/.zshrc
    fi
}

# Main logic
case "\$1" in
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
        echo "Reloading shell configuration..."
        source ~/.zshrc
        ;;
esac
