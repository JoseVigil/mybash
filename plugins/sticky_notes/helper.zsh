# plugins/sticky_notes/helper.zsh

DB_FILE="$MYBASH_DIR/db/mybash.db"

# Function to initialize the database
init_db() {
    if [[ ! -f "$DB_FILE" ]]; then
        echo "Initializing database..."
        sqlite3 "$DB_FILE" "CREATE TABLE IF NOT EXISTS general_info (key TEXT PRIMARY KEY, value TEXT);"
    fi
}

# Function to set a key-value pair in the database
db_set() {
    local key="$1"
    local value="$2"
    sqlite3 "$DB_FILE" "INSERT OR REPLACE INTO general_info (key, value) VALUES ('$key', '$value');"
}

# Function to get a value from the database
db_get() {
    local key="$1"
    sqlite3 "$DB_FILE" "SELECT value FROM general_info WHERE key = '$key';"
}

# Function to delete a key from the database
db_delete() {
    local key="$1"
    sqlite3 "$DB_FILE" "DELETE FROM general_info WHERE key = '$key';"
}