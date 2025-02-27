#!/bin/zsh


    # Synchronization functionality for bookmarks and commands

    # Load logging functionality
    source "$MYBASH_DIR/core/logger.zsh"

    # Validate dependencies
    if ! command -v jq &>/dev/null; then
        echo "Error: jq is not installed. Please install it using 'brew install jq' or 'sudo apt install jq'."
        return 1
    fi

    # Export bookmarks and commands to JSON
    export_data() {
        local export_dir="$HOME/Documents/mybash/export"
        mkdir -p "$export_dir"

        echo "Exporting bookmarks..."
        jq -R 'split("=") | {key: .[0], value: .[1]}' "$BOOKMARK_FILE" > "$export_dir/bookmarks.json"

        echo "Exporting commands..."
        jq -R 'split("=") | {key: .[0], value: .[1]}' "$CMD_BOOKMARK_FILE" > "$export_dir/commands.json"

        echo "Data exported to $export_dir"
    }

    # Import bookmarks and commands from JSON
    import_data() {
        local import_dir="$HOME/Documents/mybash/export"

        if [[ ! -d "$import_dir" ]]; then
            echo "Import directory not found: $import_dir"
            return 1
        fi

        # Create backups
        cp "$BOOKMARK_FILE" "$BOOKMARK_FILE.bak"
        cp "$CMD_BOOKMARK_FILE" "$CMD_BOOKMARK_FILE.bak"
        echo "Backup created: $BOOKMARK_FILE.bak, $CMD_BOOKMARK_FILE.bak"

        echo "Importing bookmarks..."
        if [[ -f "$import_dir/bookmarks.json" ]]; then
            jq -r '.key + "=" + .value' "$import_dir/bookmarks.json" > "$BOOKMARK_FILE"
        else
            echo "Bookmarks file not found in $import_dir"
        fi

        echo "Importing commands..."
        if [[ -f "$import_dir/commands.json" ]]; then
            jq -r '.key + "=" + .value' "$import_dir/commands.json" > "$CMD_BOOKMARK_FILE"
        else
            echo "Commands file not found in $import_dir"
        fi

        echo "Data imported from $import_dir"
    }