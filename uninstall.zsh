#!/bin/zsh

# Script to uninstall MyBash and create a mandatory backup in .tar.gz format

# ==============================
# GLOBAL VARIABLES
# ==============================

# Load MYBASH_DIR from path.conf if available, otherwise derive from script location
load_path_from_conf() {
    OPT_DIR="/opt/mybash"
    PATH_CONF="$OPT_DIR/path.conf"
    if [[ -f "$PATH_CONF" ]]; then            
        MYBASH_DIR=$(grep '^MYBASH_DIR=' "$PATH_CONF" | cut -d'=' -f2)
        MYBASH_DATA_HOME_DIR=$(grep '^MYBASH_DATA_HOME_DIR=' "$PATH_CONF" | cut -d'=' -f2)
        if [[ -n "$MYBASH_DIR" && -d "$MYBASH_DIR" ]]; then
            export MYBASH_DIR
            export MYBASH_DATA_HOME_DIR
        else
            echo "Warning: Invalid or missing MYBASH_DIR in path.conf, using script location."
            MYBASH_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
            MYBASH_DATA_HOME_DIR="/Users/$SUDO_USER/mybash"
            export MYBASH_DIR
            export MYBASH_DATA_HOME_DIR
        fi
    else
        echo "Warning: path.conf not found at $PATH_CONF, assuming MyBash is already partially uninstalled."
        MYBASH_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
        MYBASH_DATA_HOME_DIR="/Users/$SUDO_USER/mybash"
        export MYBASH_DIR
        export MYBASH_DATA_HOME_DIR
    fi
}

# Load MYBASH_DIR and MYBASH_DATA_HOME_DIR
load_path_from_conf

# Define log file in /tmp to avoid deletion issues
LOG_FILE="/tmp/uninstall_mybash.log"

# ==============================
# HELPER FUNCTIONS
# ==============================

# Log a message to the uninstall log file
log_message() {
    echo "$(date '+%Y-%m-%d %H:%M:%S') - $1" >> "$LOG_FILE"
}

# Open file explorer based on OS
open_file_explorer() {
    local dir="$1"
    if [[ "$OSTYPE" == "darwin"* ]]; then
        osascript -e 'tell application "Finder" to activate' -e 'tell application "Finder" to open POSIX file "'"$dir"'"' 2>/dev/null
    elif [[ "$OSTYPE" == "linux-gnu"* ]]; then
        xdg-open "$dir" 2>/dev/null
    elif [[ "$OSTYPE" == "msys" || "$OSTYPE" == "cygwin" ]]; then
        explorer.exe "$dir" 2>/dev/null
    else
        echo "Explorador de archivos no soportado en este sistema operativo."
    fi
}

# Select a custom directory for backup
select_custom_directory() {
    if [[ "$OSTYPE" == "darwin"* ]]; then
        SELECTED_FOLDER=$(osascript -e 'tell application "Finder" to set selectedFolder to choose folder with prompt "Selecciona una carpeta para el respaldo:"' -e 'POSIX path of selectedFolder' 2>/dev/null)
    elif [[ "$OSTYPE" == "linux-gnu"* ]]; then
        SELECTED_FOLDER=$(zenity --file-selection --directory --title="Selecciona una carpeta" 2>/dev/null)
    else
        echo "Selección de carpeta no soportada en este sistema operativo."
        exit 1
    fi
    if [[ -n "$SELECTED_FOLDER" ]]; then
        echo "Carpeta seleccionada: $SELECTED_FOLDER"
        echo "$SELECTED_FOLDER"
    else
        echo "No se seleccionó ninguna carpeta. Saliendo."
        exit 1
    fi
}

# Create a mandatory backup of MyBash data and repo in .tar.gz format
create_backup() {
    DEFAULT_BACKUP_DIR="/Users/$SUDO_USER/Documents/mybash_backup"
    TIMESTAMP=$(date '+%Y%m%d%H%M%S')
    BACKUP_SUBDIR="mybash_backup_$TIMESTAMP"
    DEFAULT_BACKUP_PATH="$DEFAULT_BACKUP_DIR/$BACKUP_SUBDIR.tar.gz"
    echo "Creando un respaldo obligatorio de tu instalación de MyBash..."
    echo "¿Dónde deseas guardar el respaldo?"
    echo "Predeterminado: $DEFAULT_BACKUP_PATH"
    echo "Escribe 'custom' para elegir una ubicación diferente, o presiona Enter para usar el predeterminado."
    read custom_choice
    if [[ "$custom_choice" == "custom" ]]; then
        echo "Selecciona una carpeta para el respaldo."
        CUSTOM_BACKUP_DIR=$(select_custom_directory)
        BACKUP_PATH="$CUSTOM_BACKUP_DIR/$BACKUP_SUBDIR.tar.gz"
    else
        BACKUP_PATH="$DEFAULT_BACKUP_PATH"
    fi
    echo "El respaldo se guardará en: $BACKUP_PATH"
    mkdir -p "$(dirname "$BACKUP_PATH")" || {
        echo "Error: No se pudo crear el directorio de respaldo en $(dirname "$BACKUP_PATH")"
        log_message "Error: Failed to create backup directory at $(dirname "$BACKUP_PATH")"
        exit 1
    }
    # Create tar.gz backup
    tar -czf "$BACKUP_PATH" -C "$MYBASH_DATA_HOME_DIR" . -C "$MYBASH_DIR" . 2>>"$LOG_FILE" && {
        echo "Respaldo creado exitosamente en $BACKUP_PATH."
        log_message "Backup created successfully at $BACKUP_PATH."
    } || {
        echo "Error: No se pudo crear el respaldo en $BACKUP_PATH."
        log_message "Error: Failed to create backup at $BACKUP_PATH"
        exit 1
    }
    echo "¿Deseas abrir la carpeta de respaldo? (y/n):"
    read open_choice
    if [[ "$open_choice" == "y" || "$open_choice" == "Y" ]]; then
        open_file_explorer "$(dirname "$BACKUP_PATH")"
    fi
}

# Remove symbolic links
remove_symlinks() {
    log_message "Removing symbolic links..."
    for link in "/usr/local/bin/myb"; do
        if [[ -e "$link" ]]; then
            sudo rm -f "$link" && {
                log_message "Removed symlink: $link"
                echo "Eliminado enlace simbólico: $link"
            } || {
                log_message "Error: Failed to remove symlink $link"
                echo "Error: No se pudo eliminar el enlace simbólico $link"
            }
        else
            log_message "Symlink $link not found. Skipping."
            echo "Enlace simbólico $link no encontrado. Omitiendo."
        fi
    done
}

# Remove all MyBash-related entries from ~/.zshrc
remove_from_zshrc() {
    log_message "Removing MyBash entries from ~/.zshrc..."
    if [[ -f ~/.zshrc ]]; then
        # Remove lines with mybash/main.zsh or mybash/core/completion.zsh, commented or not
        sed -i.bak "/[#]*source.*mybash.*main.zsh/d" ~/.zshrc 2>>"$LOG_FILE" && {
            log_message "Removed 'main.zsh' entry from ~/.zshrc."
            echo "Eliminada entrada 'main.zsh' de ~/.zshrc."
        } || {
            log_message "Error: Failed to remove 'main.zsh' entry from ~/.zshrc."
            echo "Error: No se pudo eliminar la entrada 'main.zsh' de ~/.zshrc."
        }
        sed -i.bak "/[#]*source.*mybash.*core\/completion.zsh/d" ~/.zshrc 2>>"$LOG_FILE" && {
            log_message "Removed 'completion.zsh' entry from ~/.zshrc."
            echo "Eliminada entrada 'completion.zsh' de ~/.zshrc."
        } || {
            log_message "Error: Failed to remove 'completion.zsh' entry from ~/.zshrc."
            echo "Error: No se pudo eliminar la entrada 'completion.zsh' de ~/.zshrc."
        }
        rm -f ~/.zshrc.bak
    else
        log_message "No ~/.zshrc file found. Skipping."
        echo "Archivo ~/.zshrc no encontrado. Omitiendo."
    fi
}

# Remove MyBash directories
remove_directories() {
    log_message "Removing MyBash directories..."
    # Remove data home directory
    if [[ -d "$MYBASH_DATA_HOME_DIR" ]]; then
        sudo rm -rf "$MYBASH_DATA_HOME_DIR" 2>>"$LOG_FILE" && {
            log_message "Removed data directory: $MYBASH_DATA_HOME_DIR"
            echo "Directorio de datos eliminado: $MYBASH_DATA_HOME_DIR"
        } || {
            log_message "Error: Failed to remove $MYBASH_DATA_HOME_DIR"
            echo "Error: No se pudo eliminar $MYBASH_DATA_HOME_DIR"
        }
    else
        log_message "Data directory $MYBASH_DATA_HOME_DIR not found. Skipping."
        echo "Directorio de datos $MYBASH_DATA_HOME_DIR no encontrado. Omitiendo."
    fi
    # Remove /opt/mybash
    if [[ -d "/opt/mybash" ]]; then
        sudo rm -rf "/opt/mybash" 2>>"$LOG_FILE" && {
            log_message "Removed /opt/mybash directory"
            echo "Directorio /opt/mybash eliminado."
        } || {
            log_message "Error: Failed to remove /opt/mybash"
            echo "Error: No se pudo eliminar /opt/mybash"
        }
    else
        log_message "/opt/mybash directory not found. Skipping."
        echo "Directorio /opt/mybash no encontrado. Omitiendo."
    fi
}

# Remove dependencies installed by install.sh
remove_dependencies() {
    log_message "Checking for dependencies to remove..."
    echo "¿Deseas desinstalar las dependencias instaladas por MyBash (python@3.11, tree, jq, tmux, git)? (y/n):"
    read dep_choice
    if [[ "$dep_choice" == "y" || "$dep_choice" == "Y" ]]; then
        echo "Desinstalando dependencias instaladas por MyBash..."
        for dep in "python@3.11" "tree" "jq" "tmux" "git"; do
            if sudo -u "$SUDO_USER" brew list "$dep" &>/dev/null; then
                sudo -u "$SUDO_USER" brew uninstall "$dep" 2>>"$LOG_FILE" && {
                    log_message "Removed dependency: $dep"
                    echo "Dependencia $dep desinstalada."
                } || {
                    log_message "Error: Failed to remove dependency $dep"
                    echo "Error: No se pudo desinstalar $dep"
                }
            else
                log_message "Dependency $dep not found or not installed by Homebrew. Skipping."
                echo "Dependencia $dep no encontrada o no instalada por Homebrew. Omitiendo."
            fi
        done
    else
        echo "Omitiendo desinstalación de dependencias."
        log_message "Skipping dependency removal."
    fi
}

# Confirm uninstallation
confirm_uninstall() {
    echo "¡ADVERTENCIA! Estás a punto de desinstalar MyBash."
    echo "Esto eliminará:"
    echo "  - Enlaces simbólicos en /usr/local/bin/myb"
    echo "  - Todas las entradas de MyBash en ~/.zshrc (comentadas o no)"
    echo "  - Directorio de datos en $MYBASH_DATA_HOME_DIR"
    echo "  - Configuración en /opt/mybash"
    echo "  - Opcionalmente, dependencias instaladas (python@3.11, tree, jq, tmux, git)"
    echo "El directorio del repositorio ($MYBASH_DIR) se conservará."
    echo "Se creará un respaldo obligatorio en formato .tar.gz."
    echo "¿Estás seguro de continuar? (y/n):"
    read confirm_choice
    if [[ "$confirm_choice" != "y" && "$confirm_choice" != "Y" ]]; then
        echo "Desinstalación cancelada."
        log_message "Uninstallation cancelled by user."
        exit 0
    fi
}

# ==============================
# MAIN LOGIC
# ==============================

echo "Iniciando el proceso de desinstalación de MyBash..."
log_message "Starting MyBash uninstallation process."

# Confirm uninstallation
confirm_uninstall

# Create mandatory backup
create_backup

# Remove components
remove_symlinks
remove_from_zshrc
remove_directories
remove_dependencies

echo "Desinstalación completada. Revisa el log en $LOG_FILE para más detalles."
log_message "Uninstallation completed successfully."
echo "Para reinstalar, usa 'sudo -H zsh $MYBASH_DIR/install.sh --dev' desde el directorio del repositorio."