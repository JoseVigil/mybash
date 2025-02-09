# Bookmark directory functionality
add_bookmark() {
    local name="$1"
    local path="$2"
    if [[ -z "$name" || -z "$path" ]]; then
        echo "Usage: bookmark add <name> <path>"
        return 1
    fi
    echo "$name=$path" >> "$BOOKMARK_FILE"
    echo "Bookmark '$name' added for path '$path'."
}

list_bookmarks() {
    if [[ ! -s "$BOOKMARK_FILE" ]]; then
        echo "No bookmarks found."
        return 0
    fi
    echo "Bookmarks:"
    cat "$BOOKMARK_FILE" | while IFS='=' read -r name path; do
        echo "  $name -> $path"
    done
}

remove_bookmark() {
    local name="$1"
    if [[ -z "$name" ]]; then
        echo "Usage: bookmark remove <name>"
        return 1
    fi
    if ! grep -q "^$name=" "$BOOKMARK_FILE"; then
        echo "Bookmark '$name' not found."
        return 1
    fi
    sed -i '' "/^$name=/d" "$BOOKMARK_FILE"
    echo "Bookmark '$name' removed."
}