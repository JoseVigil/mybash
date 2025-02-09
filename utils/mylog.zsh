# utils/mylog.zsh

# Logging directory and file
LOG_DIR="$HOME/Documents/mybash/log"
LOG_FILE="$LOG_DIR/mybash.log"

# Function to log events
log_event() {
    local command_name="$1"  # Name of the command/function
    shift                   # Remove the first argument
    local args="$@"         # Remaining arguments

    # Ensure log directory exists
    mkdir -p "$LOG_DIR"

    # Capture metadata using Python
    local metadata
    metadata=$(python3 "$MYBASH_DIR/tools/py/modules/log.py" "$command_name" "$args")

    # Log the event
    echo "$(date '+%Y-%m-%d %H:%M:%S') - Command: $command_name, Args: $args, Metadata: $metadata" >> "$LOG_FILE"
}