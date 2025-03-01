#!/bin/zsh

    # ==============================
    # LOAD LOGGER 
    # ==============================

    if [[ -f "$MYBASH_DIR/core/logger.zsh" ]]; then
        source "$MYBASH_DIR/core/logger.zsh"
    else
        echo "Error: Logger file not found at $MYBASH_DIR/core/logger.zsh."
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
        echo "Inside plugin_main with args: $@"  # Depuración básica
        local action="$1"
        local plugin_name="$2"
        local arg3="$3"
        local arg4="$4"

        case "$action" in
            clone)
                if [[ -z "$plugin_name" || -z "$arg3" ]]; then
                    echo "Error: Plugin name and repository URL are required."
                    echo "Usage: myb plugin clone <plugin_name> <repo_url> [--install]"
                    return 1
                fi

                local plugin_dir="$PLUGINS_DIR/$plugin_name"
                if [[ -d "$plugin_dir" ]]; then
                    echo "Error: Plugin '$plugin_name' already exists at $plugin_dir."
                    return 1
                fi

                echo "Cloning plugin '$plugin_name' from $arg3..."
                git clone "$arg3" "$plugin_dir"
                if [[ $? -ne 0 ]]; then
                    echo "Error: Failed to clone repository from $arg3."
                    return 1
                fi

                log_message "INFO" "Cloned plugin '$plugin_name' from $arg3 to $plugin_dir."
                echo "Plugin '$plugin_name' cloned successfully to $plugin_dir."

                if [[ "$arg4" == "--install" ]]; then
                    plugin_main "install" "$plugin_name"
                else
                    echo "Next step: Run 'myb plugin install $plugin_name' to enable."
                fi
                ;;
            create)
                if [[ -z "$plugin_name" ]]; then
                    echo "Error: Plugin name is required."
                    show_create_plugin_help
                    return 1
                fi

                local plugin_dir="$PLUGINS_DIR/$plugin_name"
                if [[ -d "$plugin_dir" ]]; then
                    echo "Error: Plugin '$plugin_name' already exists at $plugin_dir."
                    return 1
                fi

                mkdir -p "$plugin_dir"
                log_message "INFO" "Created plugin directory: $plugin_dir"
                echo "Created plugin directory: $plugin_dir"

                local plugin_script="$plugin_dir/${plugin_name}.zsh"
                echo "#!/bin/zsh" > "$plugin_script"
                echo "" >> "$plugin_script"
                echo "# Plugin: $plugin_name - Auto-generated plugin script" >> "$plugin_script"
                echo "" >> "$plugin_script"
                echo "# Load core dependencies" >> "$plugin_script"
                echo "source \"\$MYBASH_DIR/core/logger.zsh\"" >> "$plugin_script"
                echo "source \"\$MYBASH_DIR/db/dbhelper.zsh\"" >> "$plugin_script"
                echo "[[ -z \"\$DB_FILE\" ]] && DB_FILE=\"\$MYBASH_DIR/db/mybash.db\"" >> "$plugin_script"
                echo "" >> "$plugin_script"
                echo "# Initialize plugin-specific database table" >> "$plugin_script"
                echo "${plugin_name}_init_db() {" >> "$plugin_script"
                echo "    echo \"CREATE TABLE IF NOT EXISTS ${plugin_name} (id INTEGER PRIMARY KEY AUTOINCREMENT, timestamp TEXT NOT NULL, text TEXT NOT NULL);\" | sqlite3 \"\$DB_FILE\"" >> "$plugin_script"
                echo "    [[ \$? -eq 0 ]] && log_message \"INFO\" \"Initialized ${plugin_name} table in \$DB_FILE\" || {" >> "$plugin_script"
                echo "        log_message \"ERROR\" \"Failed to initialize ${plugin_name} table.\"" >> "$plugin_script"
                echo "        echo \"Error: Failed to initialize ${plugin_name} table.\"" >> "$plugin_script"
                echo "        exit 1" >> "$plugin_script"
                echo "    }" >> "$plugin_script"
                echo "}" >> "$plugin_script"
                echo "" >> "$plugin_script"
                echo "${plugin_name}_main() {" >> "$plugin_script"
                echo "    case \"\$1\" in" >> "$plugin_script"
                echo "        init)" >> "$plugin_script"
                echo "            ${plugin_name}_init_db" >> "$plugin_script"
                echo "            ;;" >> "$plugin_script"
                echo "        add)" >> "$plugin_script"
                echo "            shift" >> "$plugin_script"
                echo "            local timestamp=\$(date '+%Y-%m-%d %H:%M:%S')" >> "$plugin_script"
                echo "            sqlite3 \"\$DB_FILE\" \"INSERT INTO ${plugin_name} (timestamp, text) VALUES ('\$timestamp', '\$*');\"" >> "$plugin_script"
                echo "            log_message \"INFO\" \"Added ${plugin_name} entry: \$timestamp - \$*\"" >> "$plugin_script"
                echo "            echo \"Added: \$timestamp - \$*\"" >> "$plugin_script"
                echo "            ;;" >> "$plugin_script"
                echo "        list)" >> "$plugin_script"
                echo "            sqlite3 \"\$DB_FILE\" \"SELECT timestamp, text FROM ${plugin_name};\" | while IFS='|' read -r timestamp text; do" >> "$plugin_script"
                echo "                echo \"\$timestamp - \$text\"" >> "$plugin_script"
                echo "            done" >> "$plugin_script"
                echo "            ;;" >> "$plugin_script"
                echo "        *)" >> "$plugin_script"
                echo "            echo \"Usage: myb ${plugin_name} [init | add <text> | list]\"" >> "$plugin_script"
                echo "            ;;" >> "$plugin_script"
                echo "    esac" >> "$plugin_script"
                echo "}" >> "$plugin_script"
                echo "" >> "$plugin_script"
                echo "# Export plugin commands" >> "$plugin_script"
                echo "PLUGIN_COMMANDS[\"${plugin_name}.init\"]=\"${plugin_name}_main init\"" >> "$plugin_script"
                echo "PLUGIN_COMMANDS[\"${plugin_name}.add\"]=\"${plugin_name}_main add\"" >> "$plugin_script"
                echo "PLUGIN_COMMANDS[\"${plugin_name}.list\"]=\"${plugin_name}_main list\"" >> "$plugin_script"
                chmod +x "$plugin_script"
                log_message "INFO" "Created ${plugin_name}.zsh for plugin '$plugin_name'."
                echo "Created ${plugin_name}.zsh for plugin '$plugin_name'."

                echo "[general]" > "$plugin_dir/plugin.conf"
                echo "name=${plugin_name}" >> "$plugin_dir/plugin.conf"
                echo "enabled=false" >> "$plugin_dir/plugin.conf"
                log_message "INFO" "Created minimal plugin.conf for plugin '$plugin_name'."
                echo "Created minimal plugin.conf for plugin '$plugin_name'."
                echo "Plugin '$plugin_name' created successfully at $plugin_dir."

                if [[ "$arg3" == "--init-repo" ]]; then
                    cd "$plugin_dir"
                    git init
                    git add .
                    git commit -m "Initial commit for $plugin_name plugin"
                    echo "Initialized Git repository for '$plugin_name' at $plugin_dir."
                    cd - > /dev/null
                fi

                if [[ "$arg3" == "--install" || "$arg4" == "--install" ]]; then
                    plugin_main "install" "$plugin_name"
                else
                    echo "Next step: Run 'myb plugin install $plugin_name' to enable."
                fi
                ;;
            install)
                echo "Installing plugin: $plugin_name"  # Depuración básica
                if [[ -z "$plugin_name" ]]; then
                    echo "Error: Plugin name is required."
                    show_install_plugin_help
                    return 1
                fi

                local plugin_dir="$PLUGINS_DIR/$plugin_name"
                local config_file="$plugin_dir/plugin.conf"

                if [[ ! -d "$plugin_dir" ]]; then
                    echo "Error: Plugin '$plugin_name' not found in $PLUGINS_DIR."
                    return 1
                fi

                if [[ ! -f "$config_file" ]]; then
                    echo "Error: Missing plugin.conf for '$plugin_name'."
                    return 1
                fi

                mkdir -p "$MYBASH_DIR/config"
                local plugins_conf="$MYBASH_DIR/config/plugins.conf"
                if [[ ! -f "$plugins_conf" ]]; then
                    echo "# Plugin Configuration File" > "$plugins_conf"
                    echo "# Format: plugin_name=status (true/false)" >> "$plugins_conf"
                fi
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
                source "$plugin_dir/${plugin_name}.zsh"  # Carga el plugin manualmente
                if [[ $? -ne 0 ]]; then
                    echo "Error: Failed to load plugin script $plugin_dir/${plugin_name}.zsh."
                    exit 1
                fi
                log_message "INFO" "Plugin '$plugin_name' installed successfully."
                echo "Plugin '$plugin_name' installed successfully."
                ;;
            uninstall)
                if [[ -z "$plugin_name" ]]; then
                    echo "Error: Plugin name is required."
                    echo "Usage: myb plugin uninstall <plugin_name>"
                    return 1
                fi

                local plugin_dir="$PLUGINS_DIR/$plugin_name"
                if [[ ! -d "$plugin_dir" ]]; then
                    echo "Error: Plugin '$plugin_name' not found in $PLUGINS_DIR."
                    return 1
                fi

                local plugins_conf="$MYBASH_DIR/config/plugins.conf"
                if grep -q "^${plugin_name}=" "$plugins_conf" 2>/dev/null; then
                    sed -i "" "/^${plugin_name}=/d" "$plugins_conf"
                    log_message "INFO" "Removed plugin '$plugin_name' from $plugins_conf."
                fi

                sqlite3 "$DB_FILE" "DROP TABLE IF EXISTS ${plugin_name};"
                log_message "INFO" "Dropped table '${plugin_name}' from database."

                rm -rf "$plugin_dir"
                log_message "INFO" "Deleted plugin directory $plugin_dir."
                echo "Plugin '$plugin_name' uninstalled successfully."
                ;;
            *)
                echo "Error: Unknown action '$action'."
                echo "Usage: myb plugin <clone|create|install|uninstall> [args]"
                return 1
                ;;
        esac
    }

    update_or_insert_config() {
        # No implementado aún; dejar vacío por ahora
        :
    }

    show_create_plugin_help() {
        echo "Usage: myb plugin create <plugin_name> [--init-repo] [--install]"
    }

    show_install_plugin_help() {
        echo "Usage: myb plugin install <plugin_name>"
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