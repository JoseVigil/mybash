# Command bookmark functionality
add_command() {
    local name="$1"
    local command="$2"
    if [[ -z "$name" || -z "$command" ]]; then
        echo "Usage: cmd add <name> <command>"
        return 1
    fi
    echo "$name=$command" >> "$CMD_BOOKMARK_FILE"
    echo "Command bookmark '$name' added for command '$command'."
}

list_commands() {
    if [[ ! -s "$CMD_BOOKMARK_FILE" ]]; then
        echo "No command bookmarks found."
        return 0
    fi
    echo "Command Bookmarks:"
    cat "$CMD_BOOKMARK_FILE" | while IFS='=' read -r name command; do
        echo "  $name -> $command"
    done
}

remove_command() {
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