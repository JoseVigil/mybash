#!/bin/zsh

MYBASH_DIR="$(cd "$(dirname "$0")/.." && pwd)"
export MYBASH_DIR

source "$MYBASH_DIR/global.zsh" || {
    echo "$(date '+%Y-%m-%d %H:%M:%S') [ERROR] - Failed to source $MYBASH_DIR/global.zsh." >&2
    exit 1
}

source "$MYBASH_DIR/core/logger.zsh" || {
    echo "$(date '+%Y-%m-%d %H:%M:%S') [ERROR] - Failed to source $MYBASH_DIR/core/logger.zsh." >&2
    exit 1
}

check_variables() {
    for var in MYBASH_DIR MYBASH_DATA_HOME_DIR MYBASH_DATA_DIR MYBASH_LOGS_DIR MYBASH_VENV MYBASH_CONDA DB_FILE PLUGINS_DIR; do
        if [[ -z "${(P)var}" ]]; then
            log_message "WARNING" "Variable $var is not defined."
        fi
    done
}

check_python_env() {
    if [[ ! -d "$MYBASH_VENV" ]]; then
        log_message "WARNING" "Python venv not found at $MYBASH_VENV."
    elif [[ ! -x "$MYBASH_VENV/bin/python" ]]; then
        log_message "WARNING" "Python executable not found in $MYBASH_VENV/bin."
    fi
}

check_conda_env() {
    if [[ ! -d "$MYBASH_CONDA" ]]; then
        log_message "WARNING" "Conda env directory not found at $MYBASH_CONDA."
    elif ! command -v conda &>/dev/null; then
        log_message "WARNING" "Conda not found in PATH."
    fi
}

check_variables >/dev/null 2>&1
check_python_env >/dev/null 2>&1
check_conda_env >/dev/null 2>&1