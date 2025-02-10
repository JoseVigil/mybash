# plugins/sticky_notes/main.zsh

echo "sticky_notes/main.zsh loaded successfully."

# Source helper functions
source "$MYBASH_DIR/plugins/sticky_notes/helper.zsh"

# Initialize the database
init_db

# Function to create a new sticky note
create_note() {
    local title="$1"
    local content="$2"
    if [[ -z "$title" || -z "$content" ]]; then
        echo "Usage: sticky create <title> <content>"
        log_message "Error: Missing arguments for 'sticky create'."
        return 1
    fi
    db_set "note:$title" "$content"
    log_message "Created note '$title' with content '$content'."
    echo "Note '$title' created successfully."
}

# Function to list all sticky notes
list_notes() {
    log_message "Listing all sticky notes."
    echo "Listing all sticky notes:"
    local notes=$(sqlite3 "$DB_FILE" "SELECT key, value FROM general_info WHERE key LIKE 'note:%';")
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
        echo "Usage: sticky delete <title>"
        log_message "Error: Missing title for 'sticky delete'."
        return 1
    fi
    db_delete "note:$title"
    log_message "Deleted note '$title'."
    echo "Note '$title' deleted successfully."
}

# Main function for the plugin
sticky_main() {
    local action="$1"  # Primer argumento: acción (create, list, delete, etc.)
    local title="$2"   # Segundo argumento: título de la nota
    local content="$3" # Tercer argumento: contenido de la nota

    echo "DEBUG: sticky_main called with:"
    echo "  action='$action'"
    echo "  title='$title'"
    echo "  content='$content'"

    case "$action" in
        create)
            create_note "$title" "$content"
            ;;
        list)
            list_notes
            ;;
        delete)
            delete_note "$title"
            ;;
        help)
            echo "Usage: sticky <action> [options]"
            echo "Actions:"
            echo "  create <title> <content>   Create a new sticky note."
            echo "  list                       List all sticky notes."
            echo "  delete <title>             Delete a sticky note by title."
            echo "  help                       Show this help message."
            ;;
        *)
            echo "Unknown action: $action"
            echo "Run 'sticky help' for usage information."
            log_message "Error: Unknown action '$action' for 'sticky'."
            ;;
    esac
}