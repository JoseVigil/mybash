#!/bin/zsh

# Ensure the script is running in Zsh
if [[ -z "$ZSH_VERSION" ]]; then
    echo "Error: mybash requires Zsh. Please run this script using Zsh."
    exit 1
fi

# Check for sudo privileges at the start
if [[ $EUID -ne 0 ]]; then
    echo "This script requires sudo privileges for some operations (e.g., /usr/local/bin, /opt/mybash)."
    echo "Please run with sudo: sudo zsh $0 $@"
    exit 1
fi

# Set MYBASH_DIR dynamically
MYBASH_DIR="$(cd "$(dirname "$0")" && pwd)"
export MYBASH_DIR
export MYBASH_INSTALL_MODE=true

# Function to select custom directory for MYBASH_DATA_HOME_DIR via Finder
select_custom_directory() {
    if [[ "$OSTYPE" == "darwin"* ]]; then
        SELECTED_FOLDER=$(osascript -e 'tell application "Finder" to set selectedFolder to choose folder with prompt "Select a folder for mybash data:"' -e 'POSIX path of selectedFolder' 2>/dev/null)
    elif [[ "$OSTYPE" == "linux-gnu"* ]]; then
        SELECTED_FOLDER=$(zenity --file-selection --directory --title="Select a folder for mybash data" 2>/dev/null)
    else
        echo "Folder selection not supported on this operating system."
        exit 1
    fi
    if [[ -n "$SELECTED_FOLDER" ]]; then
        echo "Selected folder: $SELECTED_FOLDER"
        echo "$SELECTED_FOLDER"
    else
        echo "No folder selected. Using default."
        return 1
    fi
}

# Parse command-line arguments
MODE="prod"  # Default mode
while [[ "$#" -gt 0 ]]; do
    case "$1" in
        install)
            shift
            ;;
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
                echo "Using --prefix: MYBASH_DATA_HOME_DIR set to $MYBASH_DATA_HOME_DIR"
                shift 2
            else
                echo "Error: --prefix requires a path."
                exit 1
            fi
            ;;
        *)
            echo "Unknown option: $1"
            echo "Usage: $0 [install] [--dev | --prod | --prefix <path>]"
            exit 1
            ;;
    esac
done

# Ask user for MYBASH_DATA_HOME_DIR if not set by --prefix
if [[ -z "$MYBASH_DATA_HOME_DIR" ]]; then
    DEFAULT_DATA_DIR="/Users/$SUDO_USER/mybash"
    echo "Do you want to install mybash data in $DEFAULT_DATA_DIR? (y/n):"
    echo "If you answer 'n', you can choose another location with Finder."
    read custom_choice
    if [[ "$custom_choice" == "n" || "$custom_choice" == "N" ]]; then
        echo "Please select a folder for mybash data."
        MYBASH_DATA_HOME_DIR=$(select_custom_directory)
        if [[ -z "$MYBASH_DATA_HOME_DIR" ]]; then
            echo "No valid folder selected. Using $DEFAULT_DATA_DIR by default."
            MYBASH_DATA_HOME_DIR="$DEFAULT_DATA_DIR"
        fi
    else
        MYBASH_DATA_HOME_DIR="$DEFAULT_DATA_DIR"
        echo "Using default location: $MYBASH_DATA_HOME_DIR"
    fi
else
    echo "Using MYBASH_DATA_HOME_DIR set by --prefix: $MYBASH_DATA_HOME_DIR"
fi

# Set log directory and file
logs_dir="$MYBASH_DATA_HOME_DIR/logs"
export LOG_FILE="$logs_dir/mybash.log"  # Export LOG_FILE for logger.zsh

# Set plugins directory
export MYBASH_PLUGINS_DIR="$MYBASH_DATA_HOME_DIR/plugins"
mkdir -p "$MYBASH_PLUGINS_DIR" || {
    echo "Error: Could not create plugins directory at $MYBASH_PLUGINS_DIR"
    exit 1
}
chown -R "$SUDO_USER":staff "$MYBASH_PLUGINS_DIR"
chmod 755 "$MYBASH_PLUGINS_DIR"

# Debug: Print variables and directory status before action
echo "DEBUG: MYBASH_DIR=$MYBASH_DIR"
echo "DEBUG: MYBASH_DATA_HOME_DIR=$MYBASH_DATA_HOME_DIR"
echo "DEBUG: logs_dir=$logs_dir"
echo "DEBUG: LOG_FILE=$LOG_FILE"
echo "DEBUG: Current directory status:"
ls -ld "$logs_dir" 2>/dev/null || echo "DEBUG: The directory does not exist yet"

# Ensure log directory and file exist with correct permissions
mkdir -p "$logs_dir" || {
    echo "Error: Could not create log directory at $logs_dir"
    echo "Error: Failed to create log directory at $logs_dir" >> "/tmp/mybash_install.log"
    exit 1
}
touch "$LOG_FILE" || {
    echo "Error: Could not create log file at $LOG_FILE"
    exit 1
}
chown -R "$SUDO_USER":staff "$MYBASH_DATA_HOME_DIR" || {
    echo "Error: Could not change ownership of $MYBASH_DATA_HOME_DIR to $SUDO_USER"
    exit 1
}
chmod 755 "$logs_dir" || {
    echo "Error: Could not set permissions on $logs_dir"
    exit 1
}
chmod 644 "$LOG_FILE" || {
    echo "Error: Could not set permissions on $LOG_FILE"
    exit 1
}
echo "DEBUG: Directory and file status after setup:"
ls -ld "$logs_dir" "$LOG_FILE"

# Debug: Verify directory after creation/adjustment
echo "DEBUG: Directory status after setup:"
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
    echo "Error: func.zsh not found at $MYBASH_DIR/core/func.zsh."
    exit 1
fi

# Function to check required variables
check_required_variables() {
    local missing=false
    for var in MYBASH_DIR PLUGINS_DIR MYBASH_DATA_DIR DB_FILE SCHEMA_FILE DEPENDENCIES_CONF MYBASH_VENV; do
        if [[ -z "${(P)var}" ]]; then
            log_message "ERROR" "Required variable '$var' is not defined."
            echo "Error: Required variable '$var' is not defined."
            missing=true
        fi
    done
    if [[ "$missing" = true ]]; then
        log_message "ERROR" "One or more required variables are missing. Check global.zsh."
        echo "Error: One or more required variables are missing. Check global.zsh."
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
        echo "Installation canceled."
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
        echo "Error: Dependencies file not found at $DEPENDENCIES_CONF."
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
    echo "Checking dependencies..."

    # Check if tmuxinator is installed (required for myb start)
    if ! command -v tmuxinator &>/dev/null; then
        log_message "ERROR" "Tmuxinator not found. It is required for MyBash. Please install it manually (see README.md)."
        echo "Error: Tmuxinator not found. It is required for MyBash."
        echo "Install it manually following the instructions in README.md and try again."
        exit 1
    fi

    if [[ "$OSTYPE" == "darwin"* ]]; then
        if ! command -v brew &>/dev/null; then
            log_message "INFO" "Homebrew not found. Installing Homebrew as $SUDO_USER..."
            echo "Homebrew not found. Installing Homebrew as $SUDO_USER..."
            sudo -u "$SUDO_USER" /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)" || {
                log_message "ERROR" "Failed to install Homebrew."
                echo "Error: Failed to install Homebrew. Please install it manually."
                exit 1
            }
        fi
        for dep in "${DEPENDENCIES[@]}"; do
            package="${dep%%=*}"
            rest="${dep#*=}"
            description="${rest%%=*}"
            install_cmd="${rest#*=}"
            if [[ "$install_cmd" == brew* ]]; then
                brew_package=$(echo "$install_cmd" | sed 's/brew install //')
                if sudo -u "$SUDO_USER" brew list | grep -q "^${brew_package}$"; then
                    log_message "INFO" "$description already installed with Homebrew ($brew_package). Skipping."
                    echo "$description already installed with Homebrew ($brew_package). Skipping."
                else
                    log_message "INFO" "Installing $description ($brew_package) with '$install_cmd' as $SUDO_USER..."
                    echo "Installing $description ($brew_package)..."
                    sudo -u "$SUDO_USER" zsh -c "$install_cmd" 2>&1 | tee -a "$LOG_FILE" || {
                        log_message "ERROR" "Failed to install $brew_package. Check $LOG_FILE for details."
                        echo "Error: Failed to install $brew_package. Check $LOG_FILE for details."
                        exit 1
                    }
                fi
            elif [[ "$install_cmd" == pip* ]]; then
                # Use pip3.11 from Python 3.11
                if sudo -u "$SUDO_USER" /usr/local/Cellar/python@3.11/3.11.11/bin/pip3.11 list 2>/dev/null | grep -q "^$package "; then
                    log_message "INFO" "$description already installed with pip3.11 ($package). Skipping."
                    echo "$description already installed with pip3.11 ($package). Skipping."
                else
                    log_message "INFO" "Installing $description ($package) with pip3.11 as $SUDO_USER..."
                    echo "Installing $description ($package)..."
                    sudo -u "$SUDO_USER" /usr/local/Cellar/python@3.11/3.11.11/bin/pip3.11 install "$package" 2>&1 | tee -a "$LOG_FILE" || {
                        log_message "ERROR" "Failed to install $package with pip3.11. Check $LOG_FILE for details."
                        echo "Error: Failed to install $package with pip3.11. Check $LOG_FILE for details."
                        exit 1
                    }
                fi
            fi
        done
    elif [[ "$OSTYPE" == "linux-gnu"* ]]; then
        log_message "ERROR" "Linux support not implemented yet."
        echo "Linux support not implemented yet."
        exit 1
    else
        log_message "ERROR" "Operating system not supported for automatic dependency installation."
        echo "Operating system not supported for automatic dependency installation."
        exit 1
    fi
    log_message "INFO" "Dependency check completed."
    echo "Dependency check completed."
}

# Function to create data directories
create_data_directories() {
    log_message "INFO" "Creating data directories in $MYBASH_DATA_DIR..."
    echo "Creating data directories in $MYBASH_DATA_DIR..."
    mkdir -p "$MYBASH_DATA_DIR/log" "$MYBASH_DATA_DIR/migrate/environments" \
             "$MYBASH_DATA_DIR/migrate/import" "$MYBASH_DATA_DIR/migrate/export" \
             "$MYBASH_BACKUP_DIR" "$MYBASH_LOGS_DIR" "$MYBASH_VENVIRONMENTS" \
             "$(dirname "$BKM_BOOKMARK_FILE")" "$(dirname "$CMD_BOOKMARK_FILE")" \
             "$PLUGINS_DIR" || {
        log_message "ERROR" "Failed to create directories."
        echo "Error: Failed to create directories."
        exit 1
    }
    touch "$BKM_BOOKMARK_FILE" "$CMD_BOOKMARK_FILE" "$LOG_FILE" || {
        log_message "ERROR" "Failed to create bookmark or log files."
        echo "Error: Failed to create bookmark or log files."
        exit 1
    }
    chown -R "$SUDO_USER":staff "$MYBASH_DATA_HOME_DIR" || {
        log_message "ERROR" "Failed to set ownership to $SUDO_USER."
        echo "Error: Failed to set ownership to $SUDO_USER."
        exit 1
    }
    chmod -R u+rw "$MYBASH_DATA_HOME_DIR" || {
        log_message "ERROR" "Failed to set permissions on $MYBASH_DATA_HOME_DIR."
        echo "Error: Failed to set permissions on $MYBASH_DATA_HOME_DIR."
        exit 1
    }
    chmod 644 "$BKM_BOOKMARK_FILE" "$CMD_BOOKMARK_FILE" "$LOG_FILE" || {
        log_message "ERROR" "Failed to set file permissions."
        echo "Error: Failed to set file permissions."
        exit 1
    }
    log_message "INFO" "Data directories and files created successfully with correct permissions."
    echo "Data directories and files created successfully with correct permissions."
}

# Function to initialize SQLite database
initialize_database() {
    log_message "INFO" "Initializing database at $DB_FILE..."
    echo "Initializing database at $DB_FILE..."
    if [[ ! -f "$SCHEMA_FILE" ]]; then
        log_message "ERROR" "Schema file not found at $SCHEMA_FILE."
        echo "Error: Schema file not found at $SCHEMA_FILE."
        exit 1
    fi
    if [[ ! -f "$DB_FILE" ]]; then
        log_message "INFO" "Database file not found. Creating and initializing database..."
        echo "Database file not found. Creating and initializing database..."
        sudo -u "$SUDO_USER" sqlite3 "$DB_FILE" < "$SCHEMA_FILE" >>"$LOG_FILE" 2>&1 || {
            log_message "ERROR" "Failed to initialize database."
            echo "Error: Failed to initialize database. Check $LOG_FILE."
            exit 1
        }
        log_message "INFO" "Database initialized successfully."
        echo "Database initialized successfully."
    else
        log_message "INFO" "Database already exists at $DB_FILE. Skipping initialization."
        echo "Database already exists at $DB_FILE. Skipping initialization."
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
            echo "Error: Failed to update configuration. Check $LOG_FILE."
            exit 1
        }
        log_message "INFO" "Updated config: $key=$value"
    else
        sudo -u "$SUDO_USER" sqlite3 "$DB_FILE" "INSERT INTO config (key, value) VALUES ('$key', '$value');" || {
            log_message "ERROR" "Failed to insert config: $key=$value"
            echo "Error: Failed to insert configuration. Check $LOG_FILE."
            exit 1
        }
        log_message "INFO" "Inserted config: $key=$value"
    fi
}

# Function to add main.zsh to ~/.zshrc
add_to_zshrc() {
    local zshrc="/Users/$SUDO_USER/.zshrc"
    log_message "INFO" "Adding main.zsh to $zshrc..."
    echo "Adding main.zsh to $zshrc..."
    if ! grep -q "source \$MYBASH_DIR/main.zsh" "$zshrc"; then
        echo "" | sudo -u "$SUDO_USER" tee -a "$zshrc" >/dev/null
        echo "# Source MyBash main script" | sudo -u "$SUDO_USER" tee -a "$zshrc" >/dev/null
        echo "if [[ -f \"\$MYBASH_DIR/main.zsh\" ]]; then" | sudo -u "$SUDO_USER" tee -a "$zshrc" >/dev/null
        echo "    source \"\$MYBASH_DIR/main.zsh\"" | sudo -u "$SUDO_USER" tee -a "$zshrc" >/dev/null
        echo "fi" | sudo -u "$SUDO_USER" tee -a "$zshrc" >/dev/null
    fi
    log_message "INFO" "Added main.zsh to $zshrc."
    echo "main.zsh added to $zshrc."
}

# Function to add completion to ~/.zshrc
add_completion_to_zshrc() {
    local zshrc="/Users/$SUDO_USER/.zshrc"
    log_message "INFO" "Adding completion.zsh to $zshrc..."
    echo "Adding completion.zsh to $zshrc..."
    if ! grep -q "source \$MYBASH_DIR/core/completion.zsh" "$zshrc"; then
        echo "" | sudo -u "$SUDO_USER" tee -a "$zshrc" >/dev/null
        echo "# Source MyBash autocompletion" | sudo -u "$SUDO_USER" tee -a "$zshrc" >/dev/null
        echo "if [[ -f \"\$MYBASH_DIR/core/completion.zsh\" ]]; then" | sudo -u "$SUDO_USER" tee -a "$zshrc" >/dev/null
        echo "    source \"\$MYBASH_DIR/core/completion.zsh\"" | sudo -u "$SUDO_USER" tee -a "$zshrc" >/dev/null
        echo "fi" | sudo -u "$SUDO_USER" tee -a "$zshrc" >/dev/null
    fi
    log_message "INFO" "Added completion.zsh to $zshrc."
    echo "completion.zsh added to $zshrc."
}

# Function to create myb wrapper
create_myb_wrapper() {
    local myb_wrapper="$1"
    local parent_dir=$(dirname "$myb_wrapper")
    if [[ ! -d "$parent_dir" ]]; then
        log_message "INFO" "Directory $parent_dir does not exist. Creating it..."
        echo "Directory $parent_dir does not exist. Creating it..."
        sudo mkdir -p "$parent_dir" || {
            log_message "ERROR" "Failed to create directory $parent_dir."
            echo "Error: Failed to create directory $parent_dir."
            exit 1
        }
    fi
    if [[ -d "$myb_wrapper" ]]; then
        log_message "ERROR" "$myb_wrapper is a directory. Removing it..."
        echo "Error: $myb_wrapper is a directory. Removing it..."
        sudo rm -rf "$myb_wrapper" || {
            log_message "ERROR" "Failed to remove directory $myb_wrapper."
            echo "Error: Failed to remove directory $myb_wrapper."
            exit 1
        }
    fi
    echo '#!/bin/bash' | sudo tee "$myb_wrapper" >/dev/null
    echo '# Wrapper to ensure main.zsh runs in Zsh' | sudo tee -a "$myb_wrapper" >/dev/null
    echo "REAL_SCRIPT=\"$MYBASH_DIR/main.zsh\"" | sudo tee -a "$myb_wrapper" >/dev/null
    echo "if ! command -v zsh &> /dev/null; then" | sudo tee -a "$myb_wrapper" >/dev/null
    echo "    echo \"Error: Zsh is not installed.\" >&2" | sudo tee -a "$myb_wrapper" >/dev/null
    echo "    exit 1" | sudo tee -a "$myb_wrapper" >/dev/null
    echo "fi" | sudo tee -a "$myb_wrapper" >/dev/null
    echo "exec zsh \"\$REAL_SCRIPT\" \"\$@\"" | sudo tee -a "$myb_wrapper" >/dev/null
    sudo chmod 755 "$myb_wrapper" || {
        log_message "ERROR" "Failed to set executable permissions on $myb_wrapper."
        echo "Error: Failed to set executable permissions on $myb_wrapper."
        exit 1
    }
    if [[ ! -f "$myb_wrapper" ]]; then
        log_message "ERROR" "Failed to create myb wrapper at $myb_wrapper."
        echo "Error: Failed to create myb wrapper at $myb_wrapper."
        exit 1
    fi
    log_message "INFO" "Wrapper created successfully at $myb_wrapper."
    echo "Wrapper created successfully at $myb_wrapper."
}

# Function to create symbolic links in /usr/local/bin
create_symlinks() {
    log_message "INFO" "Creating symbolic links in /usr/local/bin..."
    echo "Creating symbolic links in /usr/local/bin..."
    local myb_wrapper="/usr/local/bin/myb"

    if [[ -e "$myb_wrapper" ]]; then
        log_message "INFO" "Removing existing myb wrapper..."
        echo "Removing existing myb wrapper..."
        sudo rm -f "$myb_wrapper" || {
            log_message "ERROR" "Failed to remove existing $myb_wrapper."
            echo "Error: Failed to remove existing $myb_wrapper."
            exit 1
        }
    fi

    create_myb_wrapper "$myb_wrapper"

    if [[ ! -x "$MYBASH_DIR/main.zsh" ]]; then
        log_message "INFO" "Making main.zsh executable..."
        echo "Making main.zsh executable..."
        sudo chmod 755 "$MYBASH_DIR/main.zsh" || {
            log_message "ERROR" "Failed to set executable permissions on $MYBASH_DIR/main.zsh."
            echo "Error: Failed to set executable permissions on $MYBASH_DIR/main.zsh."
            exit 1
        }
    fi

    log_message "INFO" "Verifying installation..."
    echo "Verifying installation..."
    if [[ -x "/usr/local/bin/myb" ]]; then
        log_message "INFO" "✅ myb installation successful!"
        echo "✅ myb installation successful!"
    else
        log_message "ERROR" "❌ myb installation failed. Please check logs."
        echo "❌ myb installation failed. Please check logs."
        exit 1
    fi

    log_message "INFO" "Only creating 'myb' symlink as single entry point."
    echo "Only creating 'myb' symlink as single entry point."
}

# Function to set up Python virtual environment
# setup_python_venv() {
#     if [[ ! -d "$MYBASH_VENV" ]]; then
#         log_message "INFO" "Creating Python venv at $MYBASH_VENV"
#         echo "Creating Python virtual environment at $MYBASH_VENV..."
#         sudo mkdir -p "$(dirname "$MYBASH_VENV")"
#         sudo chown -R "$SUDO_USER":staff "$(dirname "$MYBASH_VENV")"
#         sudo -u "$SUDO_USER" python3 -m venv "$MYBASH_VENV" || {
#             log_message "ERROR" "Failed to create Python venv"
#             echo "Error: Failed to create Python virtual environment."
#             exit 1
#         }
#     else
#         log_message "INFO" "Python venv exists at $MYBASH_VENV"
#         echo "Python virtual environment already exists at $MYBASH_VENV."
#     fi
#     sudo -u "$SUDO_USER" zsh -c "source $MYBASH_VENV/bin/activate && pip install psutil" >>"$LOG_FILE" 2>&1 || {
#         log_message "ERROR" "Failed to activate Python venv or install psutil. Check $LOG_FILE."
#         echo "Error: Failed to activate Python virtual environment or install psutil. Check $LOG_FILE."
#         exit 1
#     }
#     log_message "INFO" "Successfully installed 'psutil' in Python venv."
#     echo "'psutil' successfully installed in Python virtual environment."
# }


# Function to set up Python virtual environment, hardcoded for python3.11 
setup_python_venv() {
    if [[ ! -d "$MYBASH_VENV" ]]; then
        log_message "INFO" "Creating Python venv at $MYBASH_VENV"
        echo "Creating Python virtual environment at $MYBASH_VENV..."
        sudo mkdir -p "$(dirname "$MYBASH_VENV")"
        sudo chown -R "$SUDO_USER":staff "$(dirname "$MYBASH_VENV")"
        # Use direct path to python3.11 from Cellar
        sudo -u "$SUDO_USER" /usr/local/Cellar/python@3.11/3.11.11/bin/python3.11 -m venv "$MYBASH_VENV" || {
            log_message "ERROR" "Failed to create Python venv with python3.11"
            echo "Error: Failed to create Python virtual environment."
            exit 1
        }
    else
        log_message "INFO" "Python venv exists at $MYBASH_VENV"
        echo "Python virtual environment already exists at $MYBASH_VENV."
    fi
    sudo -u "$SUDO_USER" zsh -c "source $MYBASH_VENV/bin/activate && pip install --no-cache-dir psutil" >>"$LOG_FILE" 2>&1 || {
        log_message "ERROR" "Failed to activate Python venv or install psutil. Check $LOG_FILE."
        echo "Error: Failed to activate Python virtual environment or install psutil. Check $LOG_FILE."
        exit 1
    }
    log_message "INFO" "Successfully installed 'psutil' in Python venv."
    echo "'psutil' successfully installed in Python virtual environment."
}

# Function to create plugins directory and README
create_plugins_directory_and_readme() {
    local plugins_dir="$MYBASH_DATA_PLUGINS"  # Usar MYBASH_DATA_PLUGINS
    if [[ ! -d "$plugins_dir" ]]; then
        sudo mkdir -p "$plugins_dir"
        log_message "INFO" "Created plugins directory: $plugins_dir"
        echo "Created plugins directory: $plugins_dir"
    else
        log_message "INFO" "Plugins directory already exists: $plugins_dir"
        echo "Plugins directory already exists: $plugins_dir"
    fi

    # Create plugins.conf in $MYBASH_DIR/config/
    local config_dir="$MYBASH_DIR/config"
    local plugins_conf="$config_dir/plugins.conf"
    if [[ ! -d "$config_dir" ]]; then
        sudo mkdir -p "$config_dir"
        log_message "INFO" "Created config directory: $config_dir"
        echo "Created config directory: $config_dir"
    fi
    if [[ ! -f "$plugins_conf" ]]; then
        log_message "INFO" "Creating $plugins_conf..."
        echo "Creating $plugins_conf..."
        echo "# Plugins configuration" | sudo tee "$plugins_conf" >/dev/null
        echo "videos=true" | sudo tee -a "$plugins_conf" >/dev/null
    else
        log_message "INFO" "plugins.conf already exists: $plugins_conf"
        echo "plugins.conf already exists: $plugins_conf"
    fi

    # Create README.md
    local readme_file="$plugins_dir/README.md"
    if [[ ! -f "$readme_file" ]]; then
        log_message "INFO" "Creating $readme_file..."
        echo "Creating $readme_file..."
        echo "# Plugins in MyBash" | sudo tee "$readme_file" >/dev/null
        echo "Available plugins: videos" | sudo tee -a "$readme_file" >/dev/null
    else
        log_message "INFO" "README.md already exists in plugins directory: $readme_file"
        echo "README.md already exists in plugins directory: $readme_file"
    fi

    sudo chown -R "$SUDO_USER":staff "$plugins_dir" "$config_dir"
    sudo chmod -R 755 "$plugins_dir" "$config_dir"
}

# Function to create backup
create_backup() {
    local backup_file="$MYBASH_BACKUP_DIR/mybash_backup_$(date +%Y%m%d_%H%M%S).tar.gz"
    log_message "INFO" "Creating backup at $backup_file..."
    echo "Creating backup at $backup_file..."
    sudo tar -czf "$backup_file" "$MYBASH_DIR" 2>>"$LOG_FILE" || {
        log_message "WARNING" "Failed to create backup. Check $LOG_FILE."
        echo "Warning: Failed to create backup. Check $LOG_FILE."
    }
    log_message "INFO" "Backup created successfully."
    echo "Backup created successfully."
}

# Function to save MYBASH_DIR and MYBASH_DATA_HOME_DIR in path.conf
create_opt_directory_write_path() {
    OPT_DIR="/opt/mybash"
    PATH_CONF="$OPT_DIR/path.conf"
    if [[ ! -d "$OPT_DIR" ]]; then
        sudo mkdir -p "$OPT_DIR" || {
            log_message "ERROR" "Failed to create $OPT_DIR"
            echo "Error: Failed to create $OPT_DIR"
            exit 1
        }
        log_message "INFO" "Created directory: $OPT_DIR"
        echo "Created directory: $OPT_DIR"
    else
        log_message "INFO" "Directory already exists: $OPT_DIR"
        echo "Directory already exists: $OPT_DIR"
    fi
    if [[ -f "$PATH_CONF" ]]; then
        CURRENT_DIR=$(grep '^MYBASH_DIR=' "$PATH_CONF" | cut -d'=' -f2)
        CURRENT_DATA_DIR=$(grep '^MYBASH_DATA_HOME_DIR=' "$PATH_CONF" | cut -d'=' -f2)
        if [[ "$CURRENT_DIR" != "$MYBASH_DIR" || "$CURRENT_DATA_DIR" != "$MYBASH_DATA_HOME_DIR" ]]; then
            echo "MYBASH_DIR=$MYBASH_DIR" | sudo tee "$PATH_CONF" >/dev/null
            echo "MYBASH_DATA_HOME_DIR=$MYBASH_DATA_HOME_DIR" | sudo tee -a "$PATH_CONF" >/dev/null
            log_message "INFO" "Updated path.conf at $PATH_CONF with MYBASH_DIR=$MYBASH_DIR and MYBASH_DATA_HOME_DIR=$MYBASH_DATA_HOME_DIR"
            echo "Updated path.conf at $PATH_CONF with MYBASH_DIR=$MYBASH_DIR and MYBASH_DATA_HOME_DIR=$MYBASH_DATA_HOME_DIR"
        else
            log_message "INFO" "path.conf already exists at $PATH_CONF with correct values"
            echo "path.conf already exists at $PATH_CONF with correct values"
        fi
    else
        echo "MYBASH_DIR=$MYBASH_DIR" | sudo tee "$PATH_CONF" >/dev/null
        echo "MYBASH_DATA_HOME_DIR=$MYBASH_DATA_HOME_DIR" | sudo tee -a "$PATH_CONF" >/dev/null
        log_message "INFO" "Created path.conf at $PATH_CONF with MYBASH_DIR=$MYBASH_DIR and MYBASH_DATA_HOME_DIR=$MYBASH_DATA_HOME_DIR"
        echo "Created path.conf at $PATH_CONF with MYBASH_DIR=$MYBASH_DIR and MYBASH_DATA_HOME_DIR=$MYBASH_DATA_HOME_DIR"
    fi
}

# Function to copy files for production mode
copy_to_home_mybash() {
    HOME_MYBASH_DIR="$MYBASH_DATA_HOME_DIR"
    sudo mkdir -p "$HOME_MYBASH_DIR"
    log_message "INFO" "Copying files to $HOME_MYBASH_DIR..."
    echo "Copying files to $HOME_MYBASH_DIR..."
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
    echo "Files copied successfully to $HOME_MYBASH_DIR."
}

# Function to setup core tools configurations
setup_core_tools_configs() {
    local android_conf="$MYBASH_DIR/plugins/android/android.conf"
    local videos_conf="$MYBASH_DIR/plugins/videos/videos.conf"

    sudo -u "$SUDO_USER" mkdir -p "$MYBASH_DIR/plugins/android"
    sudo -u "$SUDO_USER" mkdir -p "$MYBASH_DIR/plugins/videos"

    if [[ ! -f "$android_conf" ]]; then
        echo "# Android plugin configuration" | sudo -u "$SUDO_USER" tee "$android_conf" >/dev/null
        echo "placeholder=" | sudo -u "$SUDO_USER" tee -a "$android_conf" >/dev/null
        log_message "INFO" "Created Android config placeholder at $android_conf"
        echo "Created Android configuration placeholder at $android_conf"
    fi

    if [[ ! -f "$videos_conf" ]]; then
        echo "# Videos plugin configuration" | sudo -u "$SUDO_USER" tee "$videos_conf" >/dev/null
        echo "placeholder=" | sudo -u "$SUDO_USER" tee -a "$videos_conf" >/dev/null
        log_message "INFO" "Created Videos config placeholder at $videos_conf"
        echo "Created Videos configuration placeholder at $videos_conf"
    fi
}

# Function to setup tmuxinator config
setup_tmuxinator() {
    local tmuxinator_dir="/Users/$SUDO_USER/.config/tmuxinator"
    local tmuxinator_config="$tmuxinator_dir/mybash.yml"
    if [[ ! -f "$tmuxinator_config" ]]; then
        sudo -u "$SUDO_USER" mkdir -p "$tmuxinator_dir"
        echo "# Project name in tmuxinator" | sudo -u "$SUDO_USER" tee "$tmuxinator_config" >/dev/null
        echo "name: mybash" | sudo -u "$SUDO_USER" tee -a "$tmuxinator_config" >/dev/null
        echo "root: $MYBASH_DIR" | sudo -u "$SUDO_USER" tee -a "$tmuxinator_config" >/dev/null
        echo "" | sudo -u "$SUDO_USER" tee -a "$tmuxinator_config" >/dev/null
        echo "# tmux session where MyBash and its plugins will run" | sudo -u "$SUDO_USER" tee -a "$tmuxinator_config" >/dev/null
        echo "windows:" | sudo -u "$SUDO_USER" tee -a "$tmuxinator_config" >/dev/null
        echo "  - mybash:" | sudo -u "$SUDO_USER" tee -a "$tmuxinator_config" >/dev/null
        echo "      layout: main-horizontal" | sudo -u "$SUDO_USER" tee -a "$tmuxinator_config" >/dev/null
        echo "      panes:" | sudo -u "$SUDO_USER" tee -a "$tmuxinator_config" >/dev/null
        echo "        - zsh -c 'myb'  # Panel 1: Command line" | sudo -u "$SUDO_USER" tee -a "$tmuxinator_config" >/dev/null
        echo "        - zsh -c 'myb videos'  # Panel 2: Videos" | sudo -u "$SUDO_USER" tee -a "$tmuxinator_config" >/dev/null
        echo "        - zsh -c 'myb android'  # Panel 3: Android" | sudo -u "$SUDO_USER" tee -a "$tmuxinator_config" >/dev/null
        echo "        - zsh -c 'tail -f \$MYBASH_LOGS_DIR/mybash.log'  # Panel 4: Real-time log" | sudo -u "$SUDO_USER" tee -a "$tmuxinator_config" >/dev/null
        log_message "INFO" "Created tmuxinator config at $tmuxinator_config"
        echo "tmuxinator config created at $tmuxinator_config"
    else
        log_message "INFO" "tmuxinator config already exists at $tmuxinator_config"
        echo "tmuxinator config already exists at $tmuxinator_config"
    fi
    sudo chown -R "$SUDO_USER":staff "$tmuxinator_dir"
}

# Function to setup cyberpunk aesthetics
setup_cyberpunk() {
    local tmux_conf="/Users/$SUDO_USER/.tmux.conf"
    if [[ ! -f "$tmux_conf" ]] || ! grep -q "set -g mouse on" "$tmux_conf"; then
        echo "# Enable mouse support" | sudo -u "$SUDO_USER" tee "$tmux_conf" >/dev/null
        echo "set -g mouse on" | sudo -u "$SUDO_USER" tee -a "$tmux_conf" >/dev/null
        echo "" | sudo -u "$SUDO_USER" tee -a "$tmux_conf" >/dev/null
        echo "# Cyberpunk aesthetics" | sudo -u "$SUDO_USER" tee -a "$tmux_conf" >/dev/null
        echo "set -g status-bg \"#000000\"" | sudo -u "$SUDO_USER" tee -a "$tmux_conf" >/dev/null
        echo "set -g status-fg \"#00ff00\"" | sudo -u "$SUDO_USER" tee -a "$tmux_conf" >/dev/null
        echo "set -g pane-border-style \"fg=#0066ff\"" | sudo -u "$SUDO_USER" tee -a "$tmux_conf" >/dev/null
        echo "set -g pane-active-border-style \"fg=#33ff99\"" | sudo -u "$SUDO_USER" tee -a "$tmux_conf" >/dev/null
        echo "set -g status-left \"#[fg=#00aaff,bg=#000000] MyBash \"" | sudo -u "$SUDO_USER" tee -a "$tmux_conf" >/dev/null
        echo "set -g status-right \"#[fg=#cccccc,bg=#000000] %Y-%m-%d %H:%M \"" | sudo -u "$SUDO_USER" tee -a "$tmux_conf" >/dev/null
        echo "set -g window-status-current-style \"fg=#33ff99,bg=#000000\"" | sudo -u "$SUDO_USER" tee -a "$tmux_conf" >/dev/null
        echo "set -g window-status-style \"fg=#0066ff,bg=#000000\"" | sudo -u "$SUDO_USER" tee -a "$tmux_conf" >/dev/null
        log_message "INFO" "Configured cyberpunk aesthetics in $tmux_conf"
        echo "Cyberpunk aesthetics configured in $tmux_conf"
    fi

    local zshrc="/Users/$SUDO_USER/.zshrc"
    if ! grep -q "Cyberpunk prompt" "$zshrc"; then
        echo "" | sudo -u "$SUDO_USER" tee -a "$zshrc" >/dev/null
        echo "# Cyberpunk prompt with animation" | sudo -u "$SUDO_USER" tee -a "$zshrc" >/dev/null
        echo "autoload -U colors && colors" | sudo -u "$SUDO_USER" tee -a "$zshrc" >/dev/null
        echo "PROMPT='%{\$fg[#00ff00]%}➜ %{\$fg[#0066ff]%}%n@%m %{\$fg[#33ff99]%}%~ %{\$reset_color%}'" | sudo -u "$SUDO_USER" tee -a "$zshrc" >/dev/null
        echo "" | sudo -u "$SUDO_USER" tee -a "$zshrc" >/dev/null
        echo "# ASCII logo in neon green on startup" | sudo -u "$SUDO_USER" tee -a "$zshrc" >/dev/null
        echo "echo -e \"\e[32m\"" | sudo -u "$SUDO_USER" tee -a "$zshrc" >/dev/null
        echo "cat << 'ASCII'" | sudo -u "$SUDO_USER" tee -a "$zshrc" >/dev/null
        echo "  m y b a s h" | sudo -u "$SUDO_USER" tee -a "$zshrc" >/dev/null
        echo "  -----------" | sudo -u "$SUDO_USER" tee -a "$zshrc" >/dev/null
        echo "  |  MyBash |" | sudo -u "$SUDO_USER" tee -a "$zshrc" >/dev/null
        echo "  -----------" | sudo -u "$SUDO_USER" tee -a "$zshrc" >/dev/null
        echo "ASCII" | sudo -u "$SUDO_USER" tee -a "$zshrc" >/dev/null
        echo "echo -e \"\e[0m\"" | sudo -u "$SUDO_USER" tee -a "$zshrc" >/dev/null
        echo "" | sudo -u "$SUDO_USER" tee -a "$zshrc" >/dev/null
        echo "# Glitch effect for invalid commands" | sudo -u "$SUDO_USER" tee -a "$zshrc" >/dev/null
        echo "command_not_found_handler() {" | sudo -u "$SUDO_USER" tee -a "$zshrc" >/dev/null
        echo "    echo -e \"\e[31m>>> ERROR: Command '\$1' not found - SYSTEM GLITCH DETECTED <<<\e[0m\"" | sudo -u "$SUDO_USER" tee -a "$zshrc" >/dev/null
        echo "    return 127" | sudo -u "$SUDO_USER" tee -a "$zshrc" >/dev/null
        echo "}" | sudo -u "$SUDO_USER" tee -a "$zshrc" >/dev/null
        echo "" | sudo -u "$SUDO_USER" tee -a "$zshrc" >/dev/null
        echo "# Source MyBash main script" | sudo -u "$SUDO_USER" tee -a "$zshrc" >/dev/null
        echo "source $MYBASH_DIR/main.zsh" | sudo -u "$SUDO_USER" tee -a "$zshrc" >/dev/null
        echo "" | sudo -u "$SUDO_USER" tee -a "$zshrc" >/dev/null
        echo "# Cyberpunk fzf colors" | sudo -u "$SUDO_USER" tee -a "$zshrc" >/dev/null
        echo "export FZF_DEFAULT_OPTS='" | sudo -u "$SUDO_USER" tee -a "$zshrc" >/dev/null
        echo "  --color=bg:#000000,bg+:#000000,fg:#cccccc,fg+:#33ff99" | sudo -u "$SUDO_USER" tee -a "$zshrc" >/dev/null
        echo "  --color=hl:#00aaff,hl+:#00ff00,info:#0066ff,marker:#ff5555" | sudo -u "$SUDO_USER" tee -a "$zshrc" >/dev/null
        echo "  --color=prompt:#00aaff,pointer:#33ff99,spinner:#0066ff,header:#cccccc" | sudo -u "$SUDO_USER" tee -a "$zshrc" >/dev/null
        echo "'" | sudo -u "$SUDO_USER" tee -a "$zshrc" >/dev/null
        log_message "INFO" "Configured cyberpunk aesthetics in $zshrc"
        echo "Cyberpunk aesthetics configured in $zshrc"
    fi
}

# Function to setup tmux mouse support
setup_tmux_mouse() {
    local tmux_conf="/Users/$SUDO_USER/.tmux.conf"
    if ! grep -q "set -g mouse on" "$tmux_conf"; then
        echo "" | sudo -u "$SUDO_USER" tee -a "$tmux_conf" >/dev/null
        echo "# Mouse support for tmux" | sudo -u "$SUDO_USER" tee -a "$tmux_conf" >/dev/null
        echo "set -g mouse on" | sudo -u "$SUDO_USER" tee -a "$tmux_conf" >/dev/null
        echo "" | sudo -u "$SUDO_USER" tee -a "$tmux_conf" >/dev/null
        if command -v pbcopy >/dev/null; then
            echo "bind -T copy-mode MouseDragEnd1Pane send-keys -X copy-pipe-and-cancel \"pbcopy\"" | sudo -u "$SUDO_USER" tee -a "$tmux_conf" >/dev/null
        elif command -v xclip >/dev/null; then
            echo "bind -T copy-mode MouseDragEnd1Pane send-keys -X copy-pipe-and-cancel \"xclip -selection clipboard\"" | sudo -u "$SUDO_USER" tee -a "$tmux_conf" >/dev/null
        elif command -v clip.exe >/dev/null; then
            echo "bind -T copy-mode MouseDragEnd1Pane send-keys -X copy-pipe-and-cancel \"clip.exe\"" | sudo -u "$SUDO_USER" tee -a "$tmux_conf" >/dev/null
        else
            echo "bind -T copy-mode MouseDragEnd1Pane send-keys -X copy-selection-and-cancel" | sudo -u "$SUDO_USER" tee -a "$tmux_conf" >/dev/null
        fi
        log_message "INFO" "Configured tmux mouse support in $tmux_conf"
        echo "tmux mouse support configured in $tmux_conf"
    else
        log_message "INFO" "tmux mouse support already configured in $tmux_conf"
        echo "tmux mouse support already configured in $tmux_conf"
    fi
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
    setup_python_venv
    echo "Step 9: Creating plugins directory..."
    create_plugins_directory_and_readme
    echo "Step 10: Creating backup..."
    create_backup
    echo "Step 11: Loading dependencies..."
    load_dependencies "$(uname -s)"
    echo "Step 12: Saving mybash directory..."
    create_opt_directory_write_path
    echo "Step 13: Setting up core tools configurations..."
    setup_core_tools_configs
    echo "Step 14: Setting up tmuxinator..."
    #setup_tmuxinator
    echo "Step 15: Setting up cyberpunk aesthetics..."
    setup_cyberpunk
    echo "Step 16: Setting up tmux mouse support..."
    setup_tmux_mouse
}

# Main install logic
case "$MODE" in
    prod)
        echo "Running in production mode..."
        log_message "INFO" "Running in production mode."
        MYBASH_DIR="/opt/mybash"
        sudo mkdir -p "$MYBASH_DIR"
        base_install_sequence
        copy_to_home_mybash
        log_message "INFO" "Production installation complete."
        echo "Production installation completed. Run 'source ~/.zshrc' to use mybash."
        ;;
    dev)
        echo "Running in development mode..."
        log_message "INFO" "Running in development mode."
        base_install_sequence
        log_message "INFO" "Development installation complete."
        echo "Development installation completed. Run 'source ~/.zshrc' to use mybash."
        ;;
esac

echo "Check the log file at $LOG_FILE for more details."