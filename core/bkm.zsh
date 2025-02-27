#!/bin/zsh

    # ==============================
    # GLOBAL VARIABLES
    # ==============================
    source "$MYBASH_DIR/global.zsh"
    source "$MYBASH_DIR/db/dbhelper.zsh"

    bkm_main() {
        log_event "$0" "$@" "INFO"
        local action="$1"
        local name="$2"
        local path="$3"
        case "$action" in
            add)
                if [[ -z "$name" || -z "$path" ]]; then
                    echo "Usage: bkm add <name> <path>"
                    return 1
                fi
                save_bookmark "$name" "$path"
                log_event "Added bookmark '$name' for path '$path'" "INFO"
                ;;
            list)
                list_bookmarks
                log_event "Listed all bookmarks" "INFO"
                ;;
            remove)
                if [[ -z "$name" ]]; then
                    echo "Usage: bkm remove <name>"
                    return 1
                fi
                sqlite3 "$DB_FILE" "DELETE FROM bookmarks WHERE name = '$name';"
                if [[ $? -eq 0 ]]; then
                    echo "Bookmark '$name' removed."
                    log_event "Removed bookmark '$name'" "INFO"
                else
                    echo "Bookmark '$name' not found."
                    log_event "Failed to remove bookmark '$name' - not found" "ERROR"
                    return 1
                fi
                ;;
            help)
                echo "Usage: bkm <action> [options]"
                echo "Actions:"
                echo "  add <name> <path>      Add a bookmark with the given name and path."
                echo "  list                   List all bookmarks."
                echo "  remove <name>          Remove a bookmark by name."
                echo "  help                   Show this help message."
                echo "Examples:"
                echo "  bkm add home '$HOME'"
                echo "  bkm list"
                echo "  bkm remove home"
                ;;
            *)
                echo "Unknown action: $action"
                echo "Run 'bkm help' for usage information."
                ;;
        esac
    }