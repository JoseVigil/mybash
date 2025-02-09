# core/cmd.zsh

CMD_BOOKMARK_FILE="$HOME/Documents/mybash/adapters/commands"

cmd() {
    log_event "$0" "$@"  # Logging with one line

    local action="$1"
    local name="$2"
    local command="$3"

    case "$action" in
        add)
            if [[ -z "$name" || -z "$command" ]]; then
                echo "Usage: cmd add <name> <command>"
                return 1
            fi
            echo "$name=$command" >> "$CMD_BOOKMARK_FILE"
            echo "Command bookmark '$name' added for command '$command'."
            ;;
        list)
            if [[ ! -s "$CMD_BOOKMARK_FILE" ]]; then
                echo "No command bookmarks found."
                return 0
            fi
            echo "Command Bookmarks:"
            cat "$CMD_BOOKMARK_FILE" | while IFS='=' read -r cmd_name cmd_command; do
                echo "  $cmd_name -> $cmd_command"
            done
            ;;
        remove)
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
            ;;
        help)
            echo "Usage: cmd <action> [options]"
            echo "Actions:"
            echo "  add <name> <command>    Add a command bookmark with the given name and command."
            echo "  list                    List all command bookmarks."
            echo "  remove <name>           Remove a command bookmark by name."
            echo "  help                    Show this help message."
            echo ""
            echo "Examples:"
            echo "  cmd add gs 'git status'"
            echo "  cmd list"
            echo "  cmd remove gs"
            ;;
        *)
            echo "Unknown action: $action"
            echo "Run 'cmd help' for usage information."
            ;;
    esac
}