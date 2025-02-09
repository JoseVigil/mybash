# Database Helper Functions

# Initialize the database
init_db() {
    local db_file="$MYBASH_DIR/db/mybash.db"
    if [[ ! -f "$db_file" ]]; then
        echo "Initializing database: $db_file"
        sqlite3 "$db_file" <<EOF
CREATE TABLE IF NOT EXISTS general_info (
    key TEXT PRIMARY KEY,
    value TEXT
);
EOF
    else
        echo "Database already exists: $db_file"
    fi
}

# Add or update a key-value pair in the database
db_set() {
    local key="$1"
    local value="$2"
    local db_file="$MYBASH_DIR/db/mybash.db"

    if [[ -z "$key" || -z "$value" ]]; then
        echo "Usage: db_set <key> <value>"
        return 1
    fi

    sqlite3 "$db_file" "INSERT OR REPLACE INTO general_info (key, value) VALUES ('$key', '$value');"
    echo "Set '$key' = '$value'"
}

# Get the value of a key from the database
db_get() {
    local key="$1"
    local db_file="$MYBASH_DIR/db/mybash.db"

    if [[ -z "$key" ]]; then
        echo "Usage: db_get <key>"
        return 1
    fi

    local value=$(sqlite3 "$db_file" "SELECT value FROM general_info WHERE key = '$key';")
    if [[ -z "$value" ]]; then
        echo "Key '$key' not found in the database."
    else
        echo "$value"
    fi
}

# Delete a key from the database
db_delete() {
    local key="$1"
    local db_file="$MYBASH_DIR/db/mybash.db"

    if [[ -z "$key" ]]; then
        echo "Usage: db_delete <key>"
        return 1
    fi

    sqlite3 "$db_file" "DELETE FROM general_info WHERE key = '$key';"
    echo "Deleted key '$key'"
}