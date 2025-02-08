#!/bin/zsh

# Define the command bookmark file location
CMD_BOOKMARK_FILE=~/.cmd_bookmarks

# Ensure the bookmark file exists
touch "$CMD_BOOKMARK_FILE"

# Function to add a command bookmark
add_cmd() {
    local name="$1"
    local command="$2"
    if [[ -z "$name" || -z "$command" ]]; then
        echo "Usage: cmd add <name> <command>"
        return 1
    fi
    if grep -q "^$name=" "$CMD_BOOKMARK_FILE"; then
        echo "Command bookmark '$name' already exists. Use 'cmd update' to modify it."
        return 1
    fi
    echo "$name=$command" >> "$CMD_BOOKMARK_FILE"
    echo "Command bookmark '$name' added for command '$command'."
}

# Function to list command bookmarks
list_cmd() {
    if [[ ! -s "$CMD_BOOKMARK_FILE" ]]; then
        echo "No command bookmarks found."
        return 0
    fi
    echo "Command Bookmarks:"
    cat "$CMD_BOOKMARK_FILE" | while IFS='=' read -r name command; do
        echo "  $name -> $command"
    done
}

# Function to remove a command bookmark
rm_cmd() {
    local name="$1"
    if [[ -z "$name" ]]; then
        echo "Usage: cmd remove <name>"
        return 1
    fi
    if ! grep -q "^$name=" "$CMD_BOOKMARK_FILE"; then
        echo "Command bookmark '$name' not found."
        return 1
    fi
    sed -i '' "/^$name=/d" "$CMD_BOOKMARK_FILE"
    echo "Command bookmark '$name' removed."
}

# Main logic
case "$1" in
    add)
        add_cmd "$2" "$3"
        ;;
    list)
        list_cmd
        ;;
    remove)
        rm_cmd "$2"
        ;;
    *)
        # Direct execution of bookmarked command
        local name="$1"
        local command=$(grep "^$name=" "$CMD_BOOKMARK_FILE" | cut -d '=' -f 2)
        if [[ -z "$command" ]]; then
            echo "Command bookmark '$name' not found."
            return 1
        fi
        eval "$command"
        ;;
esac

