# Utility functions
cpwd() {
    pwd | pbcopy
    echo "Copied current path to clipboard: $(pwd)"
}

largefiles() {
    local count=${1:-10}
    find . -type f -exec du -h {} + | sort -rh | head -n "$count"
}

opendir() {
    if [[ "$OSTYPE" == "darwin"* ]]; then
        open .
    elif [[ "$OSTYPE" == "linux-gnu"* ]]; then
        xdg-open .
    else
        echo "File explorer utility not supported on this OS."
        return 1
    fi
}

mkcd() {
    mkdir -p "$1" && cd "$1"
}

myip() {
    if [[ "$OSTYPE" == "darwin"* ]]; then
        local wifi_interface=$(networksetup -listallhardwareports | awk '/Wi-Fi/{getline; print $2}')
        if [[ -z "$wifi_interface" ]]; then
            echo "Wi-Fi interface not found."
            return 1
        fi
        local ip_address=$(ifconfig "$wifi_interface" | awk '/inet /{print $2}')
    elif [[ "$OSTYPE" == "linux-gnu"* ]]; then
        local ip_address=$(ip addr show | grep 'inet ' | grep -v '127.0.0.1' | awk '{print $2}' | cut -d '/' -f 1)
    else
        echo "IP address utility not supported on this OS."
        return 1
    fi

    if [[ -z "$ip_address" ]]; then
        echo "No IP address found."
        return 1
    fi
    echo "IP Address: $ip_address"
}

# Load a file into memory
load_file() {
    local file="$1"
    if [[ -z "$file" ]]; then
        echo "Usage: load_file <file>"
        return 1
    fi

    if [[ ! -f "$file" ]]; then
        echo "Error: File '$file' not found."
        return 1
    fi

    echo "Loading file: $file"
    cat "$file"
}

# Function to create a backup of the mybash project
function mybash_backup() {
    # Define backup directory
    BACKUP_DIR="$HOME/Documents/mybash/backup"
    TIMESTAMP=$(date '+%Y%m%d%H%M%S')
    BACKUP_PATH="$BACKUP_DIR/mybash-backup-$TIMESTAMP"

    # Ensure the backup directory exists
    mkdir -p "$BACKUP_DIR"

    # Copy the entire mybash repository to the backup location
    echo "Creating backup of $MYBASH_DIR in $BACKUP_PATH..."
    cp -r "$MYBASH_DIR" "$BACKUP_PATH"

    # Log the backup creation
    if [[ -d "$BACKUP_PATH" ]]; then
        echo "Backup created successfully: $BACKUP_PATH"
    else
        echo "Error: Backup failed."
        return 1
    fi
}

# Function to clean old backups
function mybash_clean_backups() {
    BACKUP_DIR="$HOME/Documents/mybash/backup"
    find "$BACKUP_DIR" -type d -mtime +7 -exec rm -rf {} \;
    echo "Old backups deleted from $BACKUP_DIR."
}