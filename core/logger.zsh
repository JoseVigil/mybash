#!/bin/zsh

if [[ -n "$LOGGER_LOADED" ]]; then
    return 0
fi

export LOGGER_LOADED=1
if [[ -z "$LOG_FILE" ]]; then
    echo "Warning: LOG_FILE not set by caller, using default /tmp/mybash.log"
    LOG_FILE="/tmp/mybash.log"
fi

# Define log_message as a global function
function log_message {
    local level="$1"
    local message="$2"
    local timestamp=$(date '+%Y-%m-%d %H:%M:%S')
    echo "$timestamp [$level] - $message" >> "$LOG_FILE"
}
export -f log_message

initialize_log_file() {
    local log_dir="$(dirname "$LOG_FILE")"
    if [[ ! -d "$log_dir" ]]; then
        mkdir -p "$log_dir" || {
            echo "Error: Failed to create log directory at $log_dir. Run install.sh to set up."
            exit 1
        }
        chmod 755 "$log_dir" || {
            echo "Error: Failed to set permissions on $log_dir. Check user permissions."
            exit 1
        }
    fi
    if [[ ! -f "$LOG_FILE" ]]; then
        touch "$LOG_FILE" || {
            echo "Error: Failed to create log file at $LOG_FILE. Check permissions."
            exit 1
        }
        chmod 644 "$LOG_FILE"
    fi
}