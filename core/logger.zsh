#!/bin/zsh

if [[ -n "$LOGGER_LOADED" ]]; then
    return 0
fi

export LOGGER_LOADED=1

log_message() {
    local level="$1"
    local message="$2"
    local timestamp=$(date '+%Y-%m-%d %H:%M:%S')
    # Use a default if neither LOG_FILE nor MYBASH_LOGS_DIR is set
    if [[ -z "$LOG_FILE" ]]; then
        if [[ -z "$MYBASH_LOGS_DIR" ]]; then
            LOG_FILE="/tmp/mybash.log"
            echo "Warning: Neither LOG_FILE nor MYBASH_LOGS_DIR set, using $LOG_FILE"
        else
            LOG_FILE="$MYBASH_LOGS_DIR/mybash.log"
        fi
    fi
    mkdir -p "$(dirname "$LOG_FILE")" || {
        echo "Error: Failed to create directory $(dirname "$LOG_FILE")"
        return 1
    }
    echo "$timestamp [$level] - $message" >> "$LOG_FILE" || {
        echo "Error: Failed to write to $LOG_FILE"
        return 1
    }
}
export -f log_message

initialize_log_file() {
    local log_dir="$(dirname "$LOG_FILE")"
    if [[ ! -d "$log_dir" ]]; then
        mkdir -p "$log_dir" || {
            echo "Error: Failed to create log directory at $log_dir"
            exit 1
        }
        chmod 755 "$log_dir" || {
            echo "Error: Failed to set permissions on $log_dir"
            exit 1
        }
    fi
    if [[ ! -f "$LOG_FILE" ]]; then
        touch "$LOG_FILE" || {
            echo "Error: Failed to create log file at $LOG_FILE"
            exit 1
        }
        chmod 644 "$LOG_FILE"
    fi
}

# Call initialize_log_file automatically
initialize_log_file