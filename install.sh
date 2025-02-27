#!/bin/zsh

# Ensure the script is running in Zsh
if [[ -z "$ZSH_VERSION" ]]; then
    echo "Error: mybash requires Zsh. Please run this script using Zsh."
    exit 1
fi

# Check for sudo privileges at the start
if [[ $EUID -ne 0 ]]; then
    echo "Este script requiere privilegios de sudo para algunas operaciones (e.g., /usr/local/bin, /opt/mybash)."
    echo "Por favor, corre con sudo: sudo zsh $0 $@"
    exit 1
fi

# Set MYBASH_DIR dynamically
MYBASH_DIR="$(cd "$(dirname "$0")" && pwd)"
export MYBASH_DIR
export MYBASH_INSTALL_MODE=true

# Function to select custom directory for MYBASH_DATA_HOME_DIR via Finder
select_custom_directory() {
    if [[ "$OSTYPE" == "darwin"* ]]; then
        SELECTED_FOLDER=$(osascript -e 'tell application "Finder" to set selectedFolder to choose folder with prompt "Selecciona una carpeta para datos de mybash:"' -e 'POSIX path of selectedFolder' 2>/dev/null)
    elif [[ "$OSTYPE" == "linux-gnu"* ]]; then
        SELECTED_FOLDER=$(zenity --file-selection --directory --title="Selecciona una carpeta para datos de mybash" 2>/dev/null)
    else
        echo "Selección de carpeta no soportada en este sistema operativo."
        exit 1
    fi
    if [[ -n "$SELECTED_FOLDER" ]]; then
        echo "Carpeta seleccionada: $SELECTED_FOLDER"
        echo "$SELECTED_FOLDER"
    else
        echo "No se seleccionó ninguna carpeta. Usando predeterminado."
        return 1
    fi
}

# Parse command-line arguments
MODE="prod"  # Default mode
while [[ "$#" -gt 0 ]]; do
    case "$1" in
        --dev)
            MODE="dev"
            shift
            ;;
        --prod)
            MODE="prod"
            shift
            ;;
        --prefix)
            if [[ -n "$2" ]]; then
                MYBASH_DATA_HOME_DIR="$2"
                echo "Usando --prefix: MYBASH_DATA_HOME_DIR establecido en $MYBASH_DATA_HOME_DIR"
                shift 2
            else
                echo "Error: --prefix requiere una ruta."
                exit 1
            fi
            ;;
        *)
            echo "Opción desconocida: $1"
            echo "Uso: $0 [--dev | --prod | --prefix <ruta>]"
            exit 1
            ;;
    esac
done

# Ask user for MYBASH_DATA_HOME_DIR if not set by --prefix
if [[ -z "$MYBASH_DATA_HOME_DIR" ]]; then
    DEFAULT_DATA_DIR="/Users/$SUDO_USER/mybash"
    echo "¿Deseas instalar los datos de mybash en $DEFAULT_DATA_DIR? (y/n):"
    echo "Si respondes 'n', podrás elegir otra ubicación con Finder."
    read custom_choice
    if [[ "$custom_choice" == "n" || "$custom_choice" == "N" ]]; then
        echo "Por favor, selecciona una carpeta para los datos de mybash."
        MYBASH_DATA_HOME_DIR=$(select_custom_directory)
        if [[ -z "$MYBASH_DATA_HOME_DIR" ]]; then
            echo "No se seleccionó una carpeta válida. Usando $DEFAULT_DATA_DIR por defecto."
            MYBASH_DATA_HOME_DIR="$DEFAULT_DATA_DIR"
        fi
    else
        MYBASH_DATA_HOME_DIR="$DEFAULT_DATA_DIR"
        echo "Usando ubicación predeterminada: $MYBASH_DATA_HOME_DIR"
    fi
else
    echo "Usando MYBASH_DATA_HOME_DIR establecido por --prefix: $MYBASH_DATA_HOME_DIR"
fi

# Set log directory and file
logs_dir="$MYBASH_DATA_HOME_DIR/logs"
export LOG_FILE="$logs_dir/mybash.log"  # Export LOG_FILE for logger.zsh

# Debug: Print variables and directory status before action
echo "DEBUG: MYBASH_DIR=$MYBASH_DIR"
echo "DEBUG: MYBASH_DATA_HOME_DIR=$MYBASH_DATA_HOME_DIR"
echo "DEBUG: logs_dir=$logs_dir"
echo "DEBUG: LOG_FILE=$LOG_FILE"
echo "DEBUG: Estado actual del directorio:"
ls -ld "$logs_dir" 2>/dev/null || echo "DEBUG: El directorio no existe aún"

# Ensure log directory and file exist with correct permissions
mkdir -p "$logs_dir" || {
    echo "Error: No se pudo crear el directorio de logs en $logs_dir"
    echo "Error: Failed to create log directory at $logs_dir" >> "/tmp/mybash_install.log"
    exit 1
}
touch "$LOG_FILE" || {
    echo "Error: No se pudo crear el archivo de log en $LOG_FILE"
    exit 1
}
chown -R "$SUDO_USER":staff "$MYBASH_DATA_HOME_DIR" || {
    echo "Error: No se pudo cambiar el propietario de $MYBASH_DATA_HOME_DIR a $SUDO_USER"
    exit 1
}
chmod 755 "$logs_dir" || {
    echo "Error: No se pudieron establecer permisos en $logs_dir"
    exit 1
}
chmod 644 "$LOG_FILE" || {
    echo "Error: No se pudieron establecer permisos en $LOG_FILE"
    exit 1
}
echo "DEBUG: Estado del directorio y archivo después de ajuste:"
ls -ld "$logs_dir" "$LOG_FILE"

# Debug: Verify directory after creation/adjustment
echo "DEBUG: Estado del directorio después de ajuste:"
ls -ld "$logs_dir"

# Load logger with the proper LOG_FILE
if [[ -f "$MYBASH_DIR/core/logger.zsh" ]]; then
    source "$MYBASH_DIR/core/logger.zsh"
    log_message "INFO" "Logger loaded successfully."
else
    echo "Error: Logger file not found at $MYBASH_DIR/core/logger.zsh."
    exit 1
fi
log_message "INFO" "Selected MYBASH_DATA_HOME_DIR: $MYBASH_DATA_HOME_DIR"

# Export MYBASH_DATA_HOME_DIR and load global variables
export MYBASH_DATA_HOME_DIR
source "$MYBASH_DIR/global.zsh"

# Load helper functions from func.zsh
if [[ -f "$MYBASH_DIR/core/func.zsh" ]]; then
    source "$MYBASH_DIR/core/func.zsh"
else
    log_message "ERROR" "func.zsh not found at $MYBASH_DIR/core/func.zsh."
    echo "Error: func.zsh no encontrado en $MYBASH_DIR/core/func.zsh."
    exit 1
fi

# Function to check required variables
check_required_variables() {
    local missing=false
    for var in MYBASH_DIR PLUGINS_DIR MYBASH_DATA_DIR DB_FILE SCHEMA_FILE DEPENDENCIES_CONF MYBASH_VENV; do
        if [[ -z "${(P)var}" ]]; then
            log_message "ERROR" "Required variable '$var' is not defined."
            echo "Error: Variable requerida '$var' no está definida."
            missing=true
        fi
    done
    if [[ "$missing" = true ]]; then
        log_message "ERROR" "One or more required variables are missing. Check global.zsh."
        echo "Error: Faltan una o más variables requeridas. Revisa global.zsh."
        exit 1
    fi
}

# Function to show installation plan
show_install_plan() {
    load_dependencies "$(uname -s)"
    echo "The following dependencies will be installed:"
    for dep in "${DEPENDENCIES[@]}"; do
        package="${dep%%=*}"
        rest="${dep#*=}"
        description="${rest%%=*}"
        echo " - $package: $description"
    done
    echo "Do you want to proceed? (y/n): "
    read choice
    if [[ "$choice" != "y" && "$choice" != "Y" ]]; then
        echo "Instalación cancelada."
        log_message "INFO" "Installation canceled by user."
        exit 0
    fi
}

# Function to load dependencies from config file
load_dependencies() {
    local os_type="$1"
    DEPENDENCIES=()
    local current_os=""
    if [[ ! -f "$DEPENDENCIES_CONF" ]]; then
        log_message "ERROR" "Dependencies file not found at $DEPENDENCIES_CONF."
        echo "Error: Archivo de dependencias no encontrado en $DEPENDENCIES_CONF."
        exit 1
    fi
    while IFS='=' read -r package details url install_cmd; do
        [[ -z "$package" || "$package" =~ ^[[:space:]]*# ]] && continue
        package=$(echo "$package" | tr -d '[:space:]')
        if [[ "$package" == \[*\] ]]; then
            current_os="${package//[\[\]]/}"
        elif [[ -n "$package" && "$current_os" == "$os_type" ]]; then
            DEPENDENCIES+=("$package=$details=$install_cmd")
        fi
    done < "$DEPENDENCIES_CONF"
    log_message "INFO" "Loaded dependencies for $os_type: ${DEPENDENCIES[*]}"
}

# Function to install dependencies
install_dependencies() {
    log_message "INFO" "Checking dependencies..."
    echo "Verificando dependencias..."
    if [[ "$OSTYPE" == "darwin"* ]]; then
        if ! command -v brew &>/dev/null; then
            log_message "INFO" "Homebrew not found. Installing Homebrew as $SUDO_USER..."
            echo "Instalando Homebrew como $SUDO_USER..."
            sudo -u "$SUDO_USER" /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)" || {
                log_message "ERROR" "Failed to install Homebrew."
                echo "Error: No se pudo instalar Homebrew. Instálalo manualmente."
                exit 1
            }
        fi
        for dep in "${DEPENDENCIES[@]}"; do
            package="${dep%%=*}"
            rest="${dep#*=}"
            description="${rest%%=*}"
            install_cmd="${rest#*=}"
            if command -v "$package" &>/dev/null; then
                log_message "INFO" "$description ya está instalado en el sistema (encontrado en PATH). Omitiendo."
                echo "$description ya está instalado en el sistema (encontrado en PATH). Omitiendo."
            else
                log_message "INFO" "Instalando $description ($package) con '$install_cmd' como $SUDO_USER..."
                echo "Instalando $description ($package)..."
                sudo -u "$SUDO_USER" zsh -c "$install_cmd" 2>&1 | tee -a "$LOG_FILE" || {
                    log_message "ERROR" "Failed to install $package. Check $LOG_FILE for details."
                    echo "Error: No se pudo instalar $package. Revisa $LOG_FILE para más detalles."
                    exit 1
                }
            fi
        done
    elif [[ "$OSTYPE" == "linux-gnu"* ]]; then
        # ... (Linux-specific code) ...
    else
        log_message "ERROR" "Sistema operativo no soportado para instalación automática de dependencias."
        echo "Sistema operativo no soportado para instalación automática de dependencias."
        exit 1
    fi
    log_message "INFO" "Dependency check completed."
    echo "Verificación de dependencias completada."
}

# Function to create data directories
create_data_directories() {
    log_message "INFO" "Creating data directories in $MYBASH_DATA_DIR..."
    echo "Creando directorios de datos en $MYBASH_DATA_DIR..."
    mkdir -p "$MYBASH_DATA_DIR/log" "$MYBASH_DATA_DIR/migrate/environments" \
             "$MYBASH_DATA_DIR/migrate/import" "$MYBASH_DATA_DIR/migrate/export" \
             "$MYBASH_BACKUP_DIR" "$MYBASH_LOGS_DIR" "$MYBASH_VENVIRONMENTS" \
             "$(dirname "$BKM_BOOKMARK_FILE")" "$(dirname "$CMD_BOOKMARK_FILE")" \
             "$PLUGINS_DIR" || {
        log_message "ERROR" "Failed to create directories."
        echo "Error: No se pudieron crear los directorios."
        exit 1
    }
    touch "$BKM_BOOKMARK_FILE" "$CMD_BOOKMARK_FILE" "$LOG_FILE" || {
        log_message "ERROR" "Failed to create bookmark or log files."
        echo "Error: No se pudieron crear los archivos de marcadores o log."
        exit 1
    }
    chown -R "$SUDO_USER":staff "$MYBASH_DATA_HOME_DIR" || {
        log_message "ERROR" "Failed to set ownership to $SUDO_USER."
        echo "Error: No se pudo establecer el propietario en $SUDO_USER."
        exit 1
    }
    chmod -R u+rw "$MYBASH_DATA_HOME_DIR" || {
        log_message "ERROR" "Failed to set permissions on $MYBASH_DATA_HOME_DIR."
        echo "Error: No se pudieron establecer permisos en $MYBASH_DATA_HOME_DIR."
        exit 1
    }
    chmod 644 "$BKM_BOOKMARK_FILE" "$CMD_BOOKMARK_FILE" "$LOG_FILE" || {
        log_message "ERROR" "Failed to set file permissions."
        echo "Error: No se pudieron establecer permisos en los archivos."
        exit 1
    }
    log_message "INFO" "Data directories and files created successfully with correct permissions."
    echo "Directorios y archivos de datos creados exitosamente con permisos correctos."
}

# Function to initialize SQLite database
initialize_database() {
    log_message "INFO" "Initializing database at $DB_FILE..."
    echo "Inicializando base de datos en $DB_FILE..."
    if [[ ! -f "$SCHEMA_FILE" ]]; then
        log_message "ERROR" "Schema file not found at $SCHEMA_FILE."
        echo "Error: Archivo de esquema no encontrado en $SCHEMA_FILE."
        exit 1
    fi
    if [[ ! -f "$DB_FILE" ]]; then
        log_message "INFO" "Database file not found. Creating and initializing database..."
        echo "Archivo de base de datos no encontrado. Creando e inicializando base de datos..."
        sudo -u "$SUDO_USER" sqlite3 "$DB_FILE" < "$SCHEMA_FILE" >>"$LOG_FILE" 2>&1 || {
            log_message "ERROR" "Failed to initialize database."
            echo "Error: No se pudo inicializar la base de datos. Revisa $LOG_FILE."
            exit 1
        }
        log_message "INFO" "Database initialized successfully."
        echo "Base de datos inicializada exitosamente."
    else
        log_message "INFO" "Database already exists at $DB_FILE. Skipping initialization."
        echo "La base de datos ya existe en $DB_FILE. Omitiendo inicialización."
    fi
    update_or_insert_config "app_path" "$MYBASH_DIR"
}

# Function to update or insert config in SQLite
update_or_insert_config() {
    local key="$1"
    local value="$2"
    log_message "INFO" "Updating or inserting configuration: $key=$value"
    if sudo -u "$SUDO_USER" sqlite3 "$DB_FILE" "SELECT COUNT(*) FROM config WHERE key = '$key';" | grep -q "1"; then
        sudo -u "$SUDO_USER" sqlite3 "$DB_FILE" "UPDATE config SET value = '$value' WHERE key = '$key';" || {
            log_message "ERROR" "Failed to update config: $key=$value"
            echo "Error: No se pudo actualizar la configuración. Revisa $LOG_FILE."
            exit 1
        }
        log_message "INFO" "Updated config: $key=$value"
    else
        sudo -u "$SUDO_USER" sqlite3 "$DB_FILE" "INSERT INTO config (key, value) VALUES ('$key', '$value');" || {
            log_message "ERROR" "Failed to insert config: $key=$value"
            echo "Error: No se pudo insertar la configuración. Revisa $LOG_FILE."
            exit 1
        }
        log_message "INFO" "Inserted config: $key=$value"
    fi
}

# Function to add main.zsh to ~/.zshrc
add_to_zshrc() {
    local zshrc="/Users/$SUDO_USER/.zshrc"
    log_message "INFO" "Adding main.zsh to $zshrc..."
    echo "Añadiendo main.zsh a $zshrc..."
    # Remove any existing MyBash lines
    sed -i.bak "/[#]*source.*mybash.*main.zsh/d" "$zshrc" 2>>"$LOG_FILE"
    sed -i.bak "/[#]*source.*mybash.*core\/completion.zsh/d" "$zshrc" 2>>"$LOG_FILE"
    rm -f "$zshrc.bak"
    # Add main.zsh after Conda block if it exists, otherwise at the end
    if grep -q "# <<< conda initialize <<<" "$zshrc"; then
        sed -i.bak "/# <<< conda initialize <<</a source $MYBASH_DIR/main.zsh" "$zshrc" 2>>"$LOG_FILE"
    else
        echo "source $MYBASH_DIR/main.zsh" | sudo -u "$SUDO_USER" tee -a "$zshrc" >/dev/null
    fi
    log_message "INFO" "Added main.zsh to $zshrc."
    echo "main.zsh añadido a $zshrc."
}

add_completion_to_zshrc() {
    local completion_file="$MYBASH_DIR/core/completion.zsh"
    local zshrc="/Users/$SUDO_USER/.zshrc"
    log_message "INFO" "Adding completion.zsh to $zshrc..."
    echo "Añadiendo completion.zsh a $zshrc..."
    # Add completion.zsh after main.zsh
    if grep -q "source $MYBASH_DIR/main.zsh" "$zshrc"; then
        sed -i.bak "/source $MYBASH_DIR\/main.zsh/a source $completion_file" "$zshrc" 2>>"$LOG_FILE"
    else
        echo "source $completion_file" | sudo -u "$SUDO_USER" tee -a "$zshrc" >/dev/null
    fi
    rm -f "$zshrc.bak"
    log_message "INFO" "Added completion.zsh to $zshrc."
    echo "completion.zsh añadido a $zshrc."
}

# Function to create myb wrapper
create_myb_wrapper() {
    local myb_wrapper="$1"
    local parent_dir=$(dirname "$myb_wrapper")
    if [[ ! -d "$parent_dir" ]]; then
        log_message "INFO" "Directory $parent_dir does not exist. Creating it..."
        echo "El directorio $parent_dir no existe. Creándolo..."
        sudo mkdir -p "$parent_dir" || {
            log_message "ERROR" "Failed to create directory $parent_dir."
            echo "Error: No se pudo crear el directorio $parent_dir."
            exit 1
        }
    fi
    if [[ -d "$myb_wrapper" ]]; then
        log_message "ERROR" "$myb_wrapper is a directory. Removing it..."
        echo "Error: $myb_wrapper es un directorio. Eliminándolo..."
        sudo rm -rf "$myb_wrapper" || {
            log_message "ERROR" "Failed to remove directory $myb_wrapper."
            echo "Error: No se pudo eliminar el directorio $myb_wrapper."
            exit 1
        }
    fi
    echo '#!/bin/bash' | sudo tee "$myb_wrapper" >/dev/null
    echo '# Wrapper to ensure main.zsh runs in Zsh' | sudo tee -a "$myb_wrapper" >/dev/null
    echo "REAL_SCRIPT=\"$MYBASH_DIR/main.zsh\"" | sudo tee -a "$myb_wrapper" >/dev/null
    echo "if ! command -v zsh &> /dev/null; then" | sudo tee -a "$myb_wrapper" >/dev/null
    echo "    echo \"Error: Zsh no está instalado.\" >&2" | sudo tee -a "$myb_wrapper" >/dev/null
    echo "    exit 1" | sudo tee -a "$myb_wrapper" >/dev/null
    echo "fi" | sudo tee -a "$myb_wrapper" >/dev/null
    echo "exec zsh \"\$REAL_SCRIPT\" \"\$@\"" | sudo tee -a "$myb_wrapper" >/dev/null
    sudo chmod 755 "$myb_wrapper" || {
        log_message "ERROR" "Failed to set executable permissions on $myb_wrapper."
        echo "Error: No se pudieron establecer permisos ejecutables en $myb_wrapper."
        exit 1
    }
    if [[ ! -f "$myb_wrapper" ]]; then
        log_message "ERROR" "Failed to create myb wrapper at $myb_wrapper."
        echo "Error: No se pudo crear el wrapper myb en $myb_wrapper."
        exit 1
    fi
    log_message "INFO" "Wrapper created successfully at $myb_wrapper."
    echo "Wrapper creado exitosamente en $myb_wrapper."
}

# Function to create symbolic links in /usr/local/bin
create_symlinks() {
    log_message "INFO" "Creating symbolic links in /usr/local/bin..."
    echo "Creando enlaces simbólicos en /usr/local/bin..."
    local myb_wrapper="/usr/local/bin/myb"

    if [[ -e "$myb_wrapper" ]]; then
        log_message "INFO" "Removing existing myb wrapper..."
        echo "Eliminando wrapper myb existente..."
        sudo rm -f "$myb_wrapper" || {
            log_message "ERROR" "Failed to remove existing $myb_wrapper."
            echo "Error: No se pudo eliminar el enlace existente $myb_wrapper."
            exit 1
        }
    fi

    create_myb_wrapper "$myb_wrapper"

    if [[ ! -x "$MYBASH_DIR/main.zsh" ]]; then
        log_message "INFO" "Making main.zsh executable..."
        echo "Haciendo main.zsh ejecutable..."
        sudo chmod 755 "$MYBASH_DIR/main.zsh" || {
            log_message "ERROR" "Failed to set executable permissions on $MYBASH_DIR/main.zsh."
            echo "Error: No se pudieron establecer permisos ejecutables en $MYBASH_DIR/main.zsh."
            exit 1
        }
    fi

    log_message "INFO" "Verifying installation..."
    echo "Verificando instalación..."
    if [[ -x "/usr/local/bin/myb" ]]; then
        log_message "INFO" "✅ myb installation successful!"
        echo "✓ Instalación de myb exitosa!"
    else
        log_message "ERROR" "❌ myb installation failed. Please check logs."
        echo "❌ Instalación de myb fallida. Revisa los logs."
        exit 1
    fi

    log_message "INFO" "Only creating 'myb' symlink as single entry point."
    echo "Solo se crea el enlace 'myb' como punto de entrada único."
}

# Function to set up Python virtual environment
setup_python_venv() {
    if [[ ! -d "$MYBASH_VENV" ]]; then
        log_message "INFO" "Creating Python venv at $MYBASH_VENV"
        echo "Creando entorno virtual de Python en $MYBASH_VENV..."
        sudo mkdir -p "$(dirname "$MYBASH_VENV")"
        sudo chown -R "$SUDO_USER":staff "$(dirname "$MYBASH_VENV")"
        sudo -u "$SUDO_USER" python3 -m venv "$MYBASH_VENV" || {
            log_message "ERROR" "Failed to create Python venv"
            echo "Error: No se pudo crear el entorno virtual de Python."
            exit 1
        }
    else
        log_message "INFO" "Python venv exists at $MYBASH_VENV"
        echo "El entorno virtual de Python ya existe en $MYBASH_VENV."
    fi
    # Activate venv and install psutil in one Zsh command
    sudo -u "$SUDO_USER" zsh -c "source $MYBASH_VENV/bin/activate && pip install psutil" >>"$LOG_FILE" 2>&1 || {
        log_message "ERROR" "Failed to activate Python venv or install psutil. Check $LOG_FILE."
        echo "Error: No se pudo activar el entorno virtual de Python o instalar psutil. Revisa $LOG_FILE."
        exit 1
    }
    log_message "INFO" "Successfully installed 'psutil' in Python venv."
    echo "'psutil' instalado exitosamente en el entorno virtual de Python."
}

# Function to set up Conda environment
setup_conda_env() {
    local conda_env_name="mybash_conda"
    # Check if conda is installed and accessible as $SUDO_USER
    if ! sudo -u "$SUDO_USER" command -v conda &>/dev/null; then
        log_message "WARNING" "Conda not installed or not found in PATH for $SUDO_USER. Skipping Conda environment setup."
        echo "Advertencia: Conda no está instalado o no se encuentra en el PATH para $SUDO_USER. Omitiendo configuración de entorno Conda."
        return 0  # Continue without Conda
    fi
    sudo mkdir -p "$(dirname "$MYBASH_CONDA")"
    sudo chown -R "$SUDO_USER":staff "$(dirname "$MYBASH_CONDA")"
    if sudo -u "$SUDO_USER" HOME="/Users/$SUDO_USER" conda env list | grep -q "^$conda_env_name "; then
        log_message "INFO" "Conda env $conda_env_name exists"
        echo "El entorno Conda $conda_env_name ya existe."
    else
        log_message "INFO" "Creating conda env at $MYBASH_CONDA"
        echo "Creando entorno Conda en $MYBASH_CONDA..."
        sudo -u "$SUDO_USER" HOME="/Users/$SUDO_USER" conda create -y -p "$MYBASH_CONDA" python=3.8 >>"$LOG_FILE" 2>&1 || {
            log_message "WARNING" "Failed to create conda env. Check $LOG_FILE for details. Continuing without Conda."
            echo "Advertencia: No se pudo crear el entorno Conda. Revisa $LOG_FILE para más detalles. Continuando sin Conda."
            return 0  # Continue without Conda
        }
    fi
    eval "$(sudo -u "$SUDO_USER" HOME="/Users/$SUDO_USER" conda shell.zsh hook)" || {
        log_message "WARNING" "Failed to initialize conda shell hook. Skipping Conda package installation."
        echo "Advertencia: No se pudo inicializar el hook de shell de Conda. Omitiendo instalación de paquetes Conda."
        return 0
    }
    sudo -u "$SUDO_USER" HOME="/Users/$SUDO_USER" conda activate "$MYBASH_CONDA" || {
        log_message "WARNING" "Failed to activate conda env. Skipping package installation."
        echo "Advertencia: No se pudo activar el entorno Conda. Omitiendo instalación de paquetes."
        return 0
    }
    if ! sudo -u "$SUDO_USER" HOME="/Users/$SUDO_USER" conda install -y numpy pandas >>"$LOG_FILE" 2>&1; then
        log_message "WARNING" "Failed to install conda packages. Check $LOG_FILE."
        echo "Advertencia: No se pudieron instalar los paquetes de Conda. Revisa $LOG_FILE."
        conda deactivate
        return 0
    fi
    log_message "INFO" "Conda packages installed successfully"
    echo "Paquetes de Conda instalados exitosamente."
    conda deactivate
}

# Function to set up Python and Conda environments
setup_python_conda_environments() {
    log_message "INFO" "Setting up Python and Conda environments..."
    echo "Configurando entornos de Python y Conda..."
    setup_python_venv
    setup_conda_env
    log_message "INFO" "All Python dependencies installed successfully."
    echo "Todas las dependencias de Python instaladas exitosamente."
}

# Function to create plugins directory and README
create_plugins_directory_and_readme() {
    local plugins_dir="$MYBASH_DIR/plugins"
    if [[ ! -d "$plugins_dir" ]]; then
        sudo mkdir -p "$plugins_dir"
        log_message "INFO" "Created plugins directory: $plugins_dir"
        echo "Directorio de plugins creado: $plugins_dir"
    else
        log_message "INFO" "Plugins directory already exists: $plugins_dir"
        echo "El directorio de plugins ya existe: $plugins_dir"
    fi
    local readme_file="$plugins_dir/README.md"
    if [[ ! -f "$readme_file" ]]; then
        log_message "INFO" "Creating $readme_file (to be populated separately)..."
        echo "Creando $readme_file (se completará por separado)..."
        sudo touch "$readme_file"
        echo "# Plugins in MyBash" | sudo tee "$readme_file" >/dev/null
        echo "README content will be generated separately." | sudo tee -a "$readme_file" >/dev/null
    else
        log_message "INFO" "README.md already exists in plugins directory: $readme_file"
        echo "README.md ya existe en el directorio de plugins: $readme_file"
    fi
}

# Function to create backup
create_backup() {
    local backup_file="$MYBASH_BACKUP_DIR/mybash_backup_$(date +%Y%m%d_%H%M%S).tar.gz"
    log_message "INFO" "Creating backup at $backup_file..."
    echo "Creando respaldo en $backup_file..."
    sudo tar -czf "$backup_file" "$MYBASH_DIR" 2>>"$LOG_FILE" || {
        log_message "WARNING" "Failed to create backup. Check $LOG_FILE."
        echo "Advertencia: Falló la creación del respaldo. Revisa $LOG_FILE."
    }
    log_message "INFO" "Backup created successfully."
    echo "Respaldo creado exitosamente."
}

# Function to save MYBASH_DIR and MYBASH_DATA_HOME_DIR in path.conf
create_opt_directory_write_path() {
    OPT_DIR="/opt/mybash"
    PATH_CONF="$OPT_DIR/path.conf"
    if [[ ! -d "$OPT_DIR" ]]; then
        sudo mkdir -p "$OPT_DIR" || {
            log_message "ERROR" "Failed to create $OPT_DIR"
            echo "Error: No se pudo crear $OPT_DIR"
            exit 1
        }
        log_message "INFO" "Created directory: $OPT_DIR"
        echo "Directorio creado: $OPT_DIR"
    else
        log_message "INFO" "Directory already exists: $OPT_DIR"
        echo "El directorio ya existe: $OPT_DIR"
    fi
    if [[ -f "$PATH_CONF" ]]; then
        CURRENT_DIR=$(grep '^MYBASH_DIR=' "$PATH_CONF" | cut -d'=' -f2)
        CURRENT_DATA_DIR=$(grep '^MYBASH_DATA_HOME_DIR=' "$PATH_CONF" | cut -d'=' -f2)
        if [[ "$CURRENT_DIR" != "$MYBASH_DIR" || "$CURRENT_DATA_DIR" != "$MYBASH_DATA_HOME_DIR" ]]; then
            echo "MYBASH_DIR=$MYBASH_DIR" | sudo tee "$PATH_CONF" >/dev/null
            echo "MYBASH_DATA_HOME_DIR=$MYBASH_DATA_HOME_DIR" | sudo tee -a "$PATH_CONF" >/dev/null
            log_message "INFO" "Updated path.conf at $PATH_CONF with MYBASH_DIR=$MYBASH_DIR and MYBASH_DATA_HOME_DIR=$MYBASH_DATA_HOME_DIR"
            echo "Actualizado path.conf en $PATH_CONF con MYBASH_DIR=$MYBASH_DIR y MYBASH_DATA_HOME_DIR=$MYBASH_DATA_HOME_DIR"
        else
            log_message "INFO" "path.conf already exists at $PATH_CONF with correct values"
            echo "path.conf ya existe en $PATH_CONF con valores correctos"
        fi
    else
        echo "MYBASH_DIR=$MYBASH_DIR" | sudo tee "$PATH_CONF" >/dev/null
        echo "MYBASH_DATA_HOME_DIR=$MYBASH_DATA_HOME_DIR" | sudo tee -a "$PATH_CONF" >/dev/null
        log_message "INFO" "Created path.conf at $PATH_CONF with MYBASH_DIR=$MYBASH_DIR and MYBASH_DATA_HOME_DIR=$MYBASH_DATA_HOME_DIR"
        echo "Creado path.conf en $PATH_CONF con MYBASH_DIR=$MYBASH_DIR y MYBASH_DATA_HOME_DIR=$MYBASH_DATA_HOME_DIR"
    fi
}

# Function to copy files for production mode
copy_to_home_mybash() {
    HOME_MYBASH_DIR="$MYBASH_DATA_HOME_DIR"
    sudo mkdir -p "$HOME_MYBASH_DIR"
    log_message "INFO" "Copying files to $HOME_MYBASH_DIR..."
    echo "Copiando archivos a $HOME_MYBASH_DIR..."
    DIRECTORIES=("core" "db" "plugins" "tools" "utils")
    FILES=("main.zsh" "version")
    for dir in "${DIRECTORIES[@]}"; do
        sudo cp -r "$MYBASH_DIR/$dir" "$HOME_MYBASH_DIR/" 2>>"$LOG_FILE" || true
        log_message "INFO" "Copied directory '$dir' to $HOME_MYBASH_DIR."
    done
    for file in "${FILES[@]}"; do
        sudo cp "$MYBASH_DIR/$file" "$HOME_MYBASH_DIR/" 2>>"$LOG_FILE" || true
        log_message "INFO" "Copied file '$file' to $HOME_MYBASH_DIR."
    done
    log_message "INFO" "Files copied successfully to $HOME_MYBASH_DIR."
    echo "Archivos copiados exitosamente a $HOME_MYBASH_DIR."
}

# Base install sequence
base_install_sequence() {
    echo "Step 1: Showing installation plan..."
    show_install_plan
    echo "Step 2: Installing dependencies..."
    install_dependencies
    echo "Step 3: Creating data directories..."
    create_data_directories
    echo "Step 4: Initializing SQLite database..."
    initialize_database
    echo "Step 5: Adding main.zsh to ~/.zshrc..."
    add_to_zshrc
    echo "Step 6: Adding autocompletion to ~/.zshrc..."
    add_completion_to_zshrc
    echo "Step 7: Creating symbolic links..."
    create_symlinks
    echo "Step 8: Setting up virtual environments..."
    setup_python_conda_environments
    echo "Step 9: Creating plugins directory..."
    create_plugins_directory_and_readme
    echo "Step 10: Creating backup..."
    create_backup
    echo "Step 11: Loading dependencies..."
    load_dependencies "$(uname -s)"
    echo "Step 12: Saving mybash directory..."
    create_opt_directory_write_path
}

# Main install logic
case "$MODE" in
    prod)
        echo "Ejecutando en modo producción..."
        log_message "INFO" "Running in production mode."
        MYBASH_DIR="/opt/mybash"
        sudo mkdir -p "$MYBASH_DIR"
        base_install_sequence
        copy_to_home_mybash
        log_message "INFO" "Production installation complete."
        echo "Instalación en modo producción completada. Corre 'source ~/.zshrc' para usar mybash."
        ;;
    dev)
        echo "Ejecutando en modo desarrollo..."
        log_message "INFO" "Running in development mode."
        base_install_sequence
        log_message "INFO" "Development installation complete."
        echo "Instalación en modo desarrollo completada. Corre 'source ~/.zshrc' para usar mybash."
        ;;
esac

echo "Revisa el archivo de log en $LOG_FILE para más detalles."