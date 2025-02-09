# core/bkm.zsh
BKM_BOOKMARK_FILE="$HOME/Documents/mybash/adapters/bookmarks"

bkm_main() {
    log_event "$0" "$@"  # Logging with one line
    local action="$1"
    local name="$2"
    local path="$3"
    case "$action" in
        add)
            if [[ -z "$name" || -z "$path" ]]; then
                echo "Usage: bkm add <name> <path>"
                return 1
            fi
            echo "$name=$path" >> "$BKM_BOOKMARK_FILE"
            echo "Bookmark '$name' added for path '$path'."
            ;;
        list)
            if [[ ! -s "$BKM_BOOKMARK_FILE" ]]; then
                echo "No bookmarks found."
                return 0
            fi
            echo "Bookmarks:"
            cat "$BKM_BOOKMARK_FILE" | while IFS='=' read -r bkm_name bkm_path; do
                echo "  $bkm_name -> $bkm_path"
            done
            ;;
        remove)
            if [[ -z "$name" ]]; then
                echo "Usage: bkm remove <name>"
                return 1
            fi
            if ! grep -q "^$name=" "$BKM_BOOKMARK_FILE"; then
                echo "Bookmark '$name' not found."
                return 1
            fi
            sed -i '' "/^$name=/d" "$BKM_BOOKMARK_FILE"
            echo "Bookmark '$name' removed."
            ;;
        help)
            echo "Usage: bkm <action> [options]"
            echo "Actions:"
            echo "  add <name> <path>      Add a bookmark with the given name and path."
            echo "  list                   List all bookmarks."
            echo "  remove <name>          Remove a bookmark by name."
            echo "  help                   Show this help message."
            echo ""
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