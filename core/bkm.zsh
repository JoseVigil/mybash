# core/bkm.zsh

BOOKMARK_FILE="$HOME/Documents/mybash/adapters/bookmarks"

bkm() {
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
            echo "$name=$path" >> "$BOOKMARK_FILE"
            echo "Bookmark '$name' added for path '$path'."
            ;;
        list)
            if [[ ! -s "$BOOKMARK_FILE" ]]; then
                echo "No bookmarks found."
                return 0
            fi
            echo "Bookmarks:"
            cat "$BOOKMARK_FILE" | while IFS='=' read -r bookmark_name bookmark_path; do
                echo "  $bookmark_name -> $bookmark_path"
            done
            ;;
        remove)
            if [[ -z "$name" ]]; then
                echo "Usage: bkm remove <name>"
                return 1
            fi
            if ! grep -q "^$name=" "$BOOKMARK_FILE"; then
                echo "Bookmark '$name' not found."
                return 1
            fi
            sed -i '' "/^$name=/d" "$BOOKMARK_FILE"
            echo "Bookmark '$name' removed."
            ;;
        help)
            echo "Usage: bkm <action> [options]"
            echo "Actions:"
            echo "  add <name> <path>    Add a bookmark with the given name and path."
            echo "  list                 List all bookmarks."
            echo "  remove <name>        Remove a bookmark by name."
            echo "  help                 Show this help message."
            echo ""
            echo "Examples:"
            echo "  bkm add my_project ~/Projects/my_project"
            echo "  bkm list"
            echo "  bkm remove my_project"
            ;;
        *)
            echo "Unknown action: $action"
            echo "Run 'bkm help' for usage information."
            ;;
    esac
}