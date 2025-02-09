# Helper functions for Sticky Notes

# Example: Format notes for display
format_note() {
    local title="$1"
    local content="$2"
    echo "[$title]: $content"
}