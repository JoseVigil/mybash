#!/bin/zsh

# ==============================
# GLOBAL VARIABLES
# ==============================

# Load Global Variables
source "$MYBASH_DIR/global.zsh"

# ==============================
# DATABASE HELPER FUNCTIONS
# ==============================

# Execute a SQLite command
db_execute() {
    local query="$1"
    sqlite3 "$MYBASH_DIR/db/mybash.db" "$query" || {
        echo "Error executing query: $query"
        return 1
    }
}

# Query the SQLite database and return results
db_query() {
    local query="$1"
    sqlite3 -separator '|' "$MYBASH_DIR/db/mybash.db" "$query" || {
        echo "Error querying: $query"
        return 1
    }
}

# Save a command to the database
save_command() {
    local name="$1"
    local description="$2"
    local usage="$3"
    local db_file="$MYBASH_DIR/db/mybash.db"
    if [[ -z "$name" || -z "$description" || -z "$usage" ]]; then
        echo "Usage: save_command <name> <description> <usage>"
        return 1
    fi
    db_execute "INSERT INTO commands (name, description, usage) VALUES ('$name', '$description', '$usage');"
    echo "Command '$name' saved successfully."
}

# List all commands from the database
list_commands() {
    local db_file="$MYBASH_DIR/db/mybash.db"
    echo "Available commands:"
    db_query "SELECT name, description FROM commands;" | while read -r line; do
        echo "- $line"
    done
}

# Save a bookmark to the database
save_bookmark() {
    local name="$1"
    local path="$2"
    local db_file="$MYBASH_DIR/db/mybash.db"
    if [[ -z "$name" || -z "$path" ]]; then
        echo "Usage: save_bookmark <name> <path>"
        return 1
    fi
    db_execute "INSERT INTO bookmarks (name, path) VALUES ('$name', '$path');"
    echo "Bookmark '$name' saved successfully."
}

# List all bookmarks from the database
list_bookmarks() {
    local db_file="$MYBASH_DIR/db/mybash.db"
    echo "Available bookmarks:"
    db_query "SELECT name, path FROM bookmarks;" | while read -r line; do
        echo "- $line"
    done
}

# Save a command to the history
save_history() {
    local command="$1"
    local db_file="$MYBASH_DIR/db/mybash.db"
    if [[ -z "$command" ]]; then
        echo "Usage: save_history <command>"
        return 1
    fi
    db_execute "INSERT INTO history (command) VALUES ('$command');"
    echo "Command '$command' added to history."
}

# View command history
view_history() {
    local db_file="$MYBASH_DIR/db/mybash.db"
    echo "Command history:"
    db_query "SELECT command, executed_at FROM history ORDER BY executed_at DESC;" | while read -r line; do
        echo "- $line"
    done
}