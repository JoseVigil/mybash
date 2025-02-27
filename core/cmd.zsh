#!/bin/zsh

    # ==============================
    # GLOBAL VARIABLES
    # ==============================
    source "$MYBASH_DIR/global.zsh"
    source "$MYBASH_DIR/db/dbhelper.zsh"

    cmd_main() {
        log_event "$0" "$@" "INFO"
        local action="$1"
        local name="$2"
        local command="$3"
        case "$action" in
            add)
                if [[ -z "$name" || -z "$command" ]]; then
                    echo "Usage: cmd add <name> <command>"
                    return 1
                fi
                save_command "$name" "Custom command" "$command"
                log_event "Added command '$name' with value '$command'" "INFO"
                ;;
            list)
                list_commands
                log_event "Listed all commands" "INFO"
                ;;
            remove)
                if [[ -z "$name" ]]; then
                    echo "Usage: cmd remove <name>"
                    return 1
                fi
                sqlite3 "$DB_FILE" "DELETE FROM commands WHERE name = '$name';"
                if [[ $? -eq 0 ]]; then
                    echo "Command bookmark '$name' removed."
                    log_event "Removed command '$name'" "INFO"
                else
                    echo "Command bookmark '$name' not found."
                    log_event "Failed to remove command '$name' - not found" "ERROR"
                    return 1
                fi
                ;;
            help)
                echo "Usage: cmd <action> [options]"
                echo "Actions:"
                echo "  add <name> <command>    Add a command bookmark with the given name and command."
                echo "  list                    List all command bookmarks."
                echo "  remove <name>           Remove a command bookmark by name."
                echo "  help                    Show this help message."
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