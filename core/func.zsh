#!/bin/zsh

    # ==============================
    # LOAD LOGGER 
    # ==============================

    if [[ -f "$MYBASH_DIR/core/logger.zsh" ]]; then
        source "$MYBASH_DIR/core/logger.zsh"
        if ! typeset -f log_message > /dev/null; then
            echo "Error: log_message not defined after sourcing $MYBASH_DIR/core/logger.zsh at script start."
            exit 1
        else
            echo "Debug: log_message defined at script start."
        fi
    else
        echo "Error: Logger file not found at $MYBASH_DIR/core/logger.zsh."
        exit 1
    fi

    if [[ -f "$MYBASH_DIR/db/dbhelper.zsh" ]]; then
        source "$MYBASH_DIR/db/dbhelper.zsh"
    else
        echo "Error: DBHelper file not found at $MYBASH_DIR/db/dbhelper.zsh."
        exit 1
    fi
    
    # ==============================
    # LIST AND CHECK DEPENDENCIES
    # ==============================

    list_dependencies() {
        log_message "Checking system dependencies..."
        print_colored blue "Checking system dependencies..."

        typeset -A DEPENDENCIES
        DEPENDENCIES=(
            ["tree"]="Tree utility for directory visualization"
            ["jq"]="Command-line JSON processor"
            ["python3"]="Python 3.x (required for scripts)"
            ["pip3"]="Python package manager"
            ["psutil"]="Python module for process and system monitoring"
        )

        for dep in "${!DEPENDENCIES[@]}"; do
            description="${DEPENDENCIES[$dep]}"
            if [[ "$dep" == "psutil" ]]; then
                if python3 -c "import psutil" &>>"$LOG_FILE"; then
                    print_colored green "✅ $dep: Installed ($description)"
                    log_message "Dependency '$dep' is installed."
                else
                    print_colored red "❌ $dep: Not installed ($description)"
                    log_message "Dependency '$dep' is NOT installed."
                fi
            else
                if command -v "$dep" &>>"$LOG_FILE"; then
                    print_colored green "✅ $dep: Installed ($description)"
                    log_message "Dependency '$dep' is installed."
                else
                    print_colored red "❌ $dep: Not installed ($description)"
                    log_message "Dependency '$dep' is NOT installed."
                fi
            fi
        done
        log_message "Dependency check complete."
        print_colored blue "Dependency check complete."
    }

    mybash_clean_backups() {
        find "$MYBASH_BACKUP_DIR" -type f -mtime +7 -exec rm -f {} \; 2>>"$LOG_FILE"
        log_message "Old backups deleted from $MYBASH_BACKUP_DIR."
        print_colored green "Old backups deleted from $MYBASH_BACKUP_DIR."
    }

    # ==============================
    # BACKUP INSTALLATION
    # ==============================

    create_backup() {
        local timestamp=$(date '+%Y%m%d%H%M%S')
        local backup_path="$MYBASH_BACKUP_DIR/mybash-backup-$timestamp.tar.gz"
        mkdir -p "$MYBASH_BACKUP_DIR" || {
            log_message "Error: Failed to create backup directory at $MYBASH_BACKUP_DIR."
            print_colored red "Error: Failed to create backup directory."
            exit 1
        }
        if tar -czf "$backup_path" -C "$MYBASH_DIR" . 2>>"$LOG_FILE"; then
            log_message "Backup created successfully at $backup_path."
            print_colored green "Backup created at $backup_path."
        else
            log_message "Error: Backup failed. Check $LOG_FILE."
            print_colored red "Error: Backup failed. Check logs."
            exit 1
        fi
    }

    

    # ==============================
    # INTERACTIVE MODE
    # ==============================

    interactive_mode() {
        load_interactive_commands || {
            print_colored red "Error: Failed to load interactive commands."
            return 1
        }
        print_colored blue "Entering interactive mode. Type 'exit' to quit."
        while true; do
            echo -n "(mybash) > "
            read -r input_command || break
            [[ "$input_command" == "exit" ]] && {
                print_colored blue "Exiting interactive mode."
                break
            }
            set -- $input_command
            local command_name="$1"
            shift
            if [[ -n "${INTERACTIVE_COMMANDS[$command_name]}" ]]; then
                local function_to_call="${INTERACTIVE_COMMANDS[$command_name]}"
                if declare -F "$function_to_call" &>/dev/null; then
                    "$function_to_call" "$@"
                else
                    print_colored red "Error: Function '$function_to_call' not defined."
                fi
            else
                print_colored yellow "Error: Command '$command_name' not recognized."
            fi
        done
    }

    load_interactive_commands() {
        local commands_conf="$MYBASH_DIR/commands.conf"
        if [[ ! -f "$commands_conf" ]]; then
            log_message "Warning: Interactive commands file not found at $commands_conf."
            print_colored yellow "Warning: No commands.conf found. Using defaults."
            typeset -A INTERACTIVE_COMMANDS
            INTERACTIVE_COMMANDS=(
                ["backup"]="create_backup"
                ["deps"]="list_dependencies"
            )
            return 0
        fi
        unset INTERACTIVE_COMMANDS
        typeset -A INTERACTIVE_COMMANDS
        while IFS='=' read -r command_name function_name; do
            [[ -z "$command_name" || "$command_name" == \#* ]] && continue
            command_name=$(echo "$command_name" | tr -d '[:space:]')
            function_name=$(echo "$function_name" | tr -d '[:space:]')
            INTERACTIVE_COMMANDS["$command_name"]="$function_name"
        done < "$commands_conf"
        log_message "Interactive commands loaded successfully."
    }

    # ==============================
    # UNINSTALL
    # ==============================

    uninstall() {
        print_colored blue "Starting uninstallation process..."
        remove_symlinks
        remove_from_zshrc
        remove_directories
        log_message "Uninstallation complete."
        print_colored green "Uninstallation complete. Check logs at $LOG_FILE."
    }

    remove_symlinks() {
        log_message "Removing symbolic links..."
        for link in "/usr/local/bin/myb" "/usr/local/bin/mypy"; do
            if [[ -L "$link" ]]; then
                rm -f "$link" && log_message "Removed symlink: $link"
            else
                log_message "Symlink $link not found. Skipping."
            fi
        done
    }

    remove_from_zshrc() {
        log_message "Cleaning ~/.zshrc..."
        if [[ -f ~/.zshrc ]]; then
            sed -i.bak "/source $MYBASH_DIR\/main.zsh/d" ~/.zshrc 2>>"$LOG_FILE"
            sed -i.bak "/source $MYBASH_DIR\/core\/completion.zsh/d" ~/.zshrc 2>>"$LOG_FILE"
            log_message "Removed mybash entries from ~/.zshrc."
        fi
    }

    remove_directories() {
        log_message "Removing data directories..."
        if [[ -d "$MYBASH_DATA_DIR" ]]; then
            rm -rf "$MYBASH_DATA_DIR" 2>>"$LOG_FILE" && log_message "Removed $MYBASH_DATA_DIR."
        else
            log_message "Data directory $MYBASH_DATA_DIR not found."
        fi
    }


    # ==============================
    # PLUGIN MAIN
    # ==============================

    plugin_main() {
        echo "Inside plugin_main with args: $@"  # Debugging
        local action="$1"
        local plugin_name="$2"
        shift 2
        local args="$@"

        # Verify log_message is available (loaded by main.zsh)
        if ! typeset -f log_message > /dev/null; then
            echo "Error: log_message function not available. Check loading order in main.zsh."
            exit 1
        fi

        case "$action" in
            create)
                if [[ -z "$plugin_name" ]]; then
                    echo "Error: Plugin name is required."
                    show_create_plugin_help
                    return 1
                fi

                local plugin_dir="$MYBASH_DIR/plugins/$plugin_name"  # Crear en $MYBASH_DIR/plugins
                if [[ -d "$plugin_dir" ]]; then
                    echo "Error: Plugin '$plugin_name' already exists at $plugin_dir."
                    return 1
                fi

                mkdir -p "$plugin_dir"
                log_message "INFO" "Created plugin directory: $plugin_dir"
                echo "Created plugin directory: $plugin_dir"

                # Crear main.zsh básico
                local plugin_script="$plugin_dir/main.zsh"
                echo "#!/bin/zsh" > "$plugin_script"
                echo "" >> "$plugin_script"
                echo "# Plugin: $plugin_name - Auto-generated plugin script" >> "$plugin_script"
                echo "" >> "$plugin_script"
                echo "# Load core dependencies" >> "$plugin_script"
                echo "source \"\$MYBASH_DIR/core/logger.zsh\"" >> "$plugin_script"
                echo "source \"\$MYBASH_DIR/db/dbhelper.zsh\"" >> "$plugin_script"
                echo "" >> "$plugin_script"
                echo "${plugin_name}_main() {" >> "$plugin_script"
                echo "    case \"\$1\" in" >> "$plugin_script"
                echo "        *)" >> "$plugin_script"
                echo "            echo \"Usage: myb $plugin_name [...]\"" >> "$plugin_script"
                echo "            ;;" >> "$plugin_script"
                echo "    esac" >> "$plugin_script"
                echo "}" >> "$plugin_script"
                echo "" >> "$plugin_script"
                echo "# Export plugin commands" >> "$plugin_script"
                chmod +x "$plugin_script"
                log_message "INFO" "Created main.zsh for plugin '$plugin_name'."
                echo "Created main.zsh for plugin '$plugin_name'."

                # Crear plugin.conf completo
                local config_file="$plugin_dir/plugin.conf"
                echo "[general]" > "$config_file"
                echo "name=$plugin_name" >> "$config_file"
                echo "title=$plugin_name Plugin" >> "$config_file"
                echo "description=Description for $plugin_name" >> "$config_file"
                echo "author=$USER" >> "$config_file"
                echo "link=" >> "$config_file"
                echo "[repository]" >> "$config_file"
                echo "url=" >> "$config_file"
                echo "[database]" >> "$config_file"
                echo "datadb=" >> "$config_file"
                echo "[log]" >> "$config_file"
                echo "logfile=$MYBASH_DATA_HOME_DIR/plugins/$plugin_name/${plugin_name}.log" >> "$config_file"
                log_message "INFO" "Created plugin.conf for plugin '$plugin_name'."
                echo "Created plugin.conf for plugin '$plugin_name'."

                echo "Plugin '$plugin_name' created successfully at $plugin_dir."
                echo "Next step: Edit $config_file and run 'myb plugin install $plugin_name' to install."
                ;;
            install)
                echo "Installing plugin: $plugin_name"
                if [[ -z "$plugin_name" ]]; then
                    echo "Error: Plugin name is required."
                    show_install_plugin_help
                    return 1
                fi

                local source_dir="$MYBASH_DIR/plugins/$plugin_name"
                if [[ ! -d "$source_dir" ]]; then
                    echo "Error: Plugin '$plugin_name' not found in $MYBASH_DIR/plugins."
                    return 1
                fi

                local config_file="$source_dir/plugin.conf"
                if [[ ! -f "$config_file" ]]; then
                    echo "Error: Missing plugin.conf for '$plugin_name'."
                    return 1
                fi

                local dest_dir="$MYBASH_DATA_DIR/plugins/$plugin_name"
                local data_dir="$dest_dir/data"
                local fonts_dir="$dest_dir/fonts"
                local log_dir="$dest_dir/log"
                mkdir -p "$data_dir" "$fonts_dir" "$log_dir" || {
                    log_message "ERROR" "Failed to create directories at $dest_dir"
                    echo "Error: Failed to create plugin directories."
                    return 1
                }
                chmod -R 755 "$dest_dir"
                chown -R "$USER":staff "$dest_dir"

                # Read and expand plugin.conf
                local expanded_config=$(envsubst < "$config_file")
                local datadb=$(echo "$expanded_config" | awk -F'=' '/^\[database\]/{flag=1; next} flag&&/^datadb=/{print $2; exit}' | sed 's/^[[:space:]]*//;s/[[:space:]]*$//')
                local logfile=$(echo "$expanded_config" | awk -F'=' '/^\[log\]/{flag=1; next} flag&&/^logfile=/{print $2; exit}' | sed 's/^[[:space:]]*//;s/[[:space:]]*$//')
                local repo_url=$(echo "$expanded_config" | awk -F'=' '/^\[repository\]/{flag=1; next} flag&&/^url=/{print $2; exit}' | sed 's/^[[:space:]]*//;s/[[:space:]]*$//')

                # Create logfile in $log_dir
                if [[ -n "$logfile" ]]; then
                    logfile="$log_dir/$(basename "$logfile")"
                    touch "$logfile" || {
                        log_message "ERROR" "Failed to create logfile at $logfile"
                        echo "Error: Failed to create logfile at $logfile."
                        return 1
                    }
                    chmod 644 "$logfile"
                    log_message "INFO" "Created log file for '$plugin_name' at $logfile"
                    echo "Created log file at $logfile."
                else
                    log_message "WARNING" "No logfile specified in $config_file"
                    echo "Warning: No logfile specified."
                fi

                # Update plugins.conf
                local plugins_conf="$MYBASH_DIR/config/plugins.conf"
                mkdir -p "$MYBASH_DIR/config"
                if [[ ! -f "$plugins_conf" ]]; then
                    echo "# Plugin Configuration File" > "$plugins_conf"
                    echo "# Format: plugin_name=status (true/false)" >> "$plugins_conf"
                    log_message "INFO" "Created $plugins_conf."
                fi
                if ! grep -q "^${plugin_name}=" "$plugins_conf" 2>/dev/null; then
                    echo "${plugin_name}=true" >> "$plugins_conf"
                    log_message "INFO" "Registered and enabled plugin '$plugin_name' in $plugins_conf"
                    echo "Registered and enabled plugin '$plugin_name' in $plugins_conf."
                elif grep -q "^${plugin_name}=false" "$plugins_conf"; then
                    sed -i "" "s/^${plugin_name}=false/${plugin_name}=true/" "$plugins_conf"
                    log_message "INFO" "Enabled plugin '$plugin_name' in $plugins_conf"
                    echo "Enabled plugin '$plugin_name' in $plugins_conf."
                else
                    log_message "INFO" "Plugin '$plugin_name' already enabled in $plugins_conf"
                    echo "Plugin '$plugin_name' already enabled in $plugins_conf."
                fi

                # Initialize git repository if repo= is present
                if [[ -n "$repo_url" ]]; then
                    cd "$source_dir"
                    git init
                    git add .
                    git commit -m "Initial commit for $plugin_name plugin"
                    log_message "INFO" "Initialized Git repository for '$plugin_name' at $source_dir with repo URL $repo_url"
                    echo "Initialized Git repository for '$plugin_name'."
                    cd - > /dev/null
                fi

                # Update database with dbconfig.zsh
                local dbconfig_script="$MYBASH_DIR/plugins/dbconfig.zsh"
                if [[ -f "$dbconfig_script" ]]; then
                    zsh "$dbconfig_script"
                    if [[ $? -eq 0 ]]; then
                        log_message "INFO" "Updated all plugin configurations in database"
                        echo "Updated all plugin configurations in database."
                    else
                        log_message "ERROR" "Failed to update plugin configurations in database"
                        echo "Error: Failed to update plugin configurations."
                        return 1
                    fi
                else
                    log_message "ERROR" "dbconfig.zsh not found at $dbconfig_script"
                    echo "Error: dbconfig.zsh not found."
                    return 1
                fi

                # Load the plugin script from source_dir
                if [[ -f "$source_dir/main.zsh" ]]; then
                    source "$source_dir/main.zsh"
                    if [[ $? -eq 0 ]]; then
                        log_message "INFO" "Plugin '$plugin_name' installed successfully"
                        echo "Plugin '$plugin_name' installed successfully."
                    else
                        log_message "ERROR" "Failed to load plugin script $source_dir/main.zsh"
                        echo "Error: Failed to load plugin script."
                        return 1
                    fi
                else
                    log_message "ERROR" "main.zsh not found in $source_dir"
                    echo "Error: main.zsh not found."
                    return 1
                fi
                ;;
            *)
                echo "Error: Unknown action '$action'."
                echo "Usage: myb plugin <clone|create|install|uninstall> [args]"
                return 1
                ;;
        esac
    }

    show_create_plugin_help() {
        echo "Usage: myb plugin create <plugin_name>"
    }

    # ==============================
    # INSTALL PLUGIN
    # ==============================
    
    install_plugin() {
        local plugin_name="$1"

        if [[ -z "$plugin_name" ]]; then
            echo "Error: Plugin name is required."
            show_install_plugin_help
            return 1
        fi

        local plugin_dir="$PLUGINS_DIR/$plugin_name"
        local config_file="$plugin_dir/plugin.conf"

        if [[ ! -d "$plugin_dir" ]]; then
            echo "Error: Plugin '$plugin_name' not found in $PLUGINS_DIR. Run 'myb create-plugin $plugin_name' first."
            return 1
        fi

        if [[ ! -f "$config_file" ]]; then
            echo "Error: Missing plugin.conf for '$plugin_name'."
            return 1
        fi

        local plugins_conf="$MYBASH_DIR/config/plugins.conf"
        if ! grep -q "^${plugin_name}=" "$plugins_conf" 2>/dev/null; then
            echo "${plugin_name}=true" >> "$plugins_conf"
            log_message "INFO" "Registered and enabled plugin '$plugin_name' in $plugins_conf."
        elif grep -q "^${plugin_name}=false" "$plugins_conf"; then
            sed -i "" "s/^${plugin_name}=false/${plugin_name}=true/" "$plugins_conf"
            log_message "INFO" "Enabled plugin '$plugin_name' in $plugins_conf."
        else
            log_message "INFO" "Plugin '$plugin_name' already enabled in $plugins_conf."
        fi

        update_or_insert_config "plugin_$plugin_name" "$plugin_dir"
        load_plugin "$plugin_name"
        echo "Plugin '$plugin_name' installed successfully."
    }

    show_install_plugin_help() {
        echo "Usage: myb install-plugin <plugin_name>"
        echo "Installs a plugin from a local directory or clones it from a specified repository."
        echo "If the plugin is not found locally, it checks $MYBASH_DIR/config/plugins.conf for repo info."
    }