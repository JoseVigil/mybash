#!/bin/zsh

# Self-check script for MyBash installation

# Define MYBASH_DIR relativo a la ubicación del script
MYBASH_DIR="$(cd "$(dirname "$0")/.." && pwd)"
export MYBASH_DIR

# Carga global.zsh para variables esenciales
source "$MYBASH_DIR/global.zsh" || {
    echo "$(date '+%Y-%m-%d %H:%M:%S') [ERROR] - Failed to source $MYBASH_DIR/global.zsh."
    exit 1
}

# Carga logger.zsh para registro
source "$MYBASH_DIR/core/logger.zsh" || {
    echo "$(date '+%Y-%m-%d %H:%M:%S') [ERROR] - Failed to source $MYBASH_DIR/core/logger.zsh."
    exit 1
}

# Carga loader.zsh para scripts esenciales
source "$MYBASH_DIR/core/loader.zsh" || {
    echo "$(date '+%Y-%m-%d %H:%M:%S') [ERROR] - Failed to source $MYBASH_DIR/core/loader.zsh."
    exit 1
}
load_core_scripts

log_message "INFO" "Starting MyBash self-check..."

# Verifica variables esenciales
check_variables() {
    log_message "INFO" "Checking required variables..."
    for var in MYBASH_DIR MYBASH_DATA_HOME_DIR MYBASH_DATA_DIR MYBASH_LOGS_DIR MYBASH_VENV MYBASH_CONDA DB_FILE PLUGINS_DIR; do
        if [[ -z "${(P)var}" ]]; then
            log_message "WARNING" "Variable $var is not defined."
            echo "WARNING: Variable $var no está definida."
        else
            log_message "INFO" "Variable $var is set to ${(P)var}."
        fi
    done
}

# Verifica entorno Python
check_python_env() {
    log_message "INFO" "Checking Python virtual environment..."
    if [[ -d "$MYBASH_VENV" ]]; then
        log_message "INFO" "Python venv found at $MYBASH_VENV."
        if [[ -x "$MYBASH_VENV/bin/python" ]]; then
            log_message "INFO" "Python executable found in venv."
            local python_version
            python_version=$("$MYBASH_VENV/bin/python" --version 2>&1)
            if [[ $? -eq 0 ]]; then
                log_message "INFO" "Python version in venv: $python_version"
            else
                log_message "WARNING" "Failed to get Python version: $python_version"
                echo "WARNING: No se pudo obtener la versión de Python en $MYBASH_VENV."
            fi
        else
            log_message "WARNING" "Python executable not found in $MYBASH_VENV/bin."
            echo "WARNING: No se encontró ejecutable de Python en $MYBASH_VENV/bin."
        fi
    else
        log_message "WARNING" "Python venv not found at $MYBASH_VENV."
        echo "WARNING: Entorno virtual de Python no encontrado en $MYBASH_VENV."
    fi
}

# Verifica entorno Conda
check_conda_env() {
    log_message "INFO" "Checking Conda environment..."
    if [[ -d "$MYBASH_CONDA" ]]; then
        log_message "INFO" "Conda env found at $MYBASH_CONDA."
        if command -v conda &>/dev/null; then
            conda info --base | log_message "INFO" "Conda base environment: $(cat -)"
            if conda env list | grep -q "mybash_conda"; then
                log_message "INFO" "Conda environment 'mybash_conda' exists."
            else
                log_message "WARNING" "Conda environment 'mybash_conda' not found."
                echo "WARNING: Entorno Conda 'mybash_conda' no encontrado."
            fi
        else
            log_message "WARNING" "Conda not found in PATH."
            echo "WARNING: Conda no encontrado en PATH."
        fi
    else
        log_message "WARNING" "Conda env directory not found at $MYBASH_CONDA."
        echo "WARNING: Directorio de entorno Conda no encontrado en $MYBASH_CONDA."
    fi
}

# Ejecuta verificaciones
check_variables
check_python_env
check_conda_env

log_message "INFO" "Self-check completed."
echo "Verificación completa. Revisa $MYBASH_LOGS_DIR/mybash.log para más detalles."