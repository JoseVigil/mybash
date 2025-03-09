#!/bin/zsh

MYBASH_DIR="$(cd "$(dirname "$0")/.." && pwd)"
export MYBASH_DIR

source "$MYBASH_DIR/global.zsh" || {
    echo "$(date '+%Y-%m-%d %H:%M:%S') [ERROR] - Failed to source $MYBASH_DIR/global.zsh." >&2
    exit 1
}

echo "Starting MyBash self-check..."

check_variables() {
    echo "Checking variables..."
    for var in MYBASH_DIR MYBASH_DATA_HOME_DIR MYBASH_DATA_DIR MYBASH_LOGS_DIR MYBASH_VENV MYBASH_CONDA DB_FILE PLUGINS_DIR; do
        if [[ -z "${(P)var}" ]]; then
            echo "WARNING: Variable $var is not defined."
        else
            echo "OK: $var is defined as ${(P)var}"
        fi
    done
}

check_python_env() {
    echo "Checking Python environment..."
    if [[ ! -d "$MYBASH_VENV" ]]; then
        echo "WARNING: Python venv not found at $MYBASH_VENV."
    elif [[ ! -x "$MYBASH_VENV/bin/python" ]]; then
        echo "WARNING: Python executable not found in $MYBASH_VENV/bin."
    else
        echo "OK: Python venv found at $MYBASH_VENV with executable."
    fi
}

check_conda_env() {
    echo "Checking Conda environment..."
    if [[ ! -d "$MYBASH_CONDA" ]]; then
        echo "WARNING: Conda env directory not found at $MYBASH_CONDA."
    elif ! command -v conda &>/dev/null; then
        echo "WARNING: Conda not found in PATH."
    else
        echo "OK: Conda env found at $MYBASH_CONDA and conda command available."
    fi
}

check_variables
check_python_env
check_conda_env

echo "Self-check completed."