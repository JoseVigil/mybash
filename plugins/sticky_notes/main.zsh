# Plugin: Sticky Notes

# Function to create a new sticky note
create_note() {
    local title="$1"
    local content="$2"
    if [[ -z "$title" || -z "$content" ]]; then
        echo "Usage: create_note <title> <content>"
        return 1
    fi

    db_set "note:$title" "$content"
    echo "Note '$title' created successfully."
}

# Function to view all sticky notes
list_notes() {
    echo "Listing all sticky notes:"
    local notes=$(sqlite3 "$MYBASH_DIR/db/mybash.db" "SELECT key, value FROM general_info WHERE key LIKE 'note:%';")
    if [[ -z "$notes" ]]; then
        echo "No sticky notes found."
    else
        echo "$notes" | while IFS='|' read -r key value; do
            echo "Title: ${key#note:}"
            echo "Content: $value"
            echo "-------------------------"
        done
    fi
}

# Function to delete a sticky note
delete_note() {
    local title="$1"
    if [[ -z "$title" ]]; then
        echo "Usage: delete_note <title>"
        return 1
    fi

    db_delete "note:$title"
}

# Source the helper functions
source "$MYBASH_DIR/plugins/sticky_notes/helper.zsh"