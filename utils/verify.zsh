#!/bin/zsh

# Verify MyBash installation

# Reload ~/.zshrc to apply MyBash configuration to the current shell
log_message() {
    # Temporary logger until core/logger.zsh is sourced
    local level="$1"
    local message="$2"
    local timestamp=$(date '+%Y-%m-%d %H:%M:%S')
    echo "$timestamp [$level] - $message"
}
log_message "INFO" "Reloading ~/.zshrc to apply MyBash configuration..."
source ~/.zshrc || {
    log_message "ERROR" "Failed to source ~/.zshrc. Check if it exists and is readable."
    exit 1
}

# Load global variables
source "$MYBASH_DIR/global.zsh" || {
    log_message "ERROR" "Failed to source $MYBASH_DIR/global.zsh."
    exit 1
}

# Load logger
source "$MYBASH_DIR/core/logger.zsh" || {
    log_message "ERROR" "Failed to source $MYBASH_DIR/core/logger.zsh."
    exit 1
}

log_message "INFO" "Starting MyBash installation verification..."

# Check MYBASH_DIR and MYBASH_DATA_HOME_DIR
if [[ ! -d "$MYBASH_DIR" ]]; then
    log_message "ERROR" "MYBASH_DIR ($MYBASH_DIR) does not exist."
    exit 1
fi
log_message "INFO" "MYBASH_DIR is set to $MYBASH_DIR"

if [[ ! -d "$MYBASH_DATA_HOME_DIR" ]]; then
    log_message "ERROR" "MYBASH_DATA_HOME_DIR ($MYBASH_DATA_HOME_DIR) does not exist."
    exit 1
fi
log_message "INFO" "MYBASH_DATA_HOME_DIR is set to $MYBASH_DATA_HOME_DIR"

# Check key directories
for dir in "$MYBASH_DATA_DIR" "$MYBASH_BACKUP_DIR" "$MYBASH_LOGS_DIR" "$PLUGINS_DIR"; do
    if [[ ! -d "$dir" ]]; then
        log_message "ERROR" "Directory $dir does not exist."
        exit 1
    fi
    log_message "INFO" "Directory $dir exists."
done

# Check log file
if [[ ! -f "$LOG_FILE" ]]; then
    log_message "ERROR" "Log file $LOG_FILE does not exist."
    exit 1
fi
log_message "INFO" "Log file $LOG_FILE exists."

# Check database file
if [[ ! -f "$DB_FILE" ]]; then
    log_message "ERROR" "Database file $DB_FILE does not exist."
    exit 1
fi
log_message "INFO" "Database file $DB_FILE exists."

# Check wrapper
if [[ ! -x "/usr/local/bin/myb" ]]; then
    log_message "ERROR" "MyBash wrapper /usr/local/bin/myb does not exist or is not executable."
    exit 1
fi
log_message "INFO" "MyBash wrapper /usr/local/bin/myb is executable."

# Check Python venv
if [[ ! -d "$MYBASH_VENV" ]]; then
    log_message "WARNING" "Python virtual environment $MYBASH_VENV does not exist."
else
    if ! source "$MYBASH_VENV/bin/activate" || ! python -c "import psutil" &>/dev/null; then
        log_message "WARNING" "Python venv $MYBASH_VENV exists but psutil is not installed or functional."
    else
        log_message "INFO" "Python venv $MYBASH_VENV is set up with psutil."
    fi
    deactivate
fi

# Check Conda env
if [[ ! -d "$MYBASH_CONDA" ]]; then
    log_message "WARNING" "Conda environment $MYBASH_CONDA does not exist."
else
    if ! conda activate "$MYBASH_CONDA" || ! python -c "import numpy, pandas" &>/dev/null; then
        log_message "WARNING" "Conda env $MYBASH_CONDA exists but numpy/pandas are not installed or functional."
    else
        log_message "INFO" "Conda env $MYBASH_CONDA is set up with numpy and pandas."
    fi
    conda deactivate
fi

log_message "INFO" "MyBash installation verification completed."
echo "Verificación completada. Revisa el log en $LOG_FILE para más detalles."