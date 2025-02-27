#!/bin/zsh

    # ==============================
    # LOAD LOGGER 
    # ==============================
    
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
    # CREATE PLUGIN
    # ==============================
    create_plugin() {
        local plugin_name="$1"
        if [[ -z "$plugin_name" ]]; then
            echo "Error: Plugin name is required."
            show_create_plugin_help
            return 1
        fi

        local plugin_dir="$MYBASH_DIR/plugins/$plugin_name"
        if [[ -d "$plugin_dir" ]]; then
            echo "Error: Plugin '$plugin_name' already exists at $plugin_dir."
            return 1
        fi

        # Create plugin directory
        mkdir -p "$plugin_dir"
        log_message "Created plugin directory: $plugin_dir"

        # Create main.zsh entry point
        echo "#!/bin/zsh" > "$plugin_dir/main.zsh"
        echo "" >> "$plugin_dir/main.zsh"
        echo "# Load core logger and database helper" >> "$plugin_dir/main.zsh"
        echo "source \"\$MYBASH_DIR/core/logger.zsh\"" >> "$plugin_dir/main.zsh"
        echo "source \"\$MYBASH_DIR/db/dbhelper.zsh\"" >> "$plugin_dir/main.zsh"
        echo "" >> "$plugin_dir/main.zsh"
        echo "${plugin_name}_main() {" >> "$plugin_dir/main.zsh"
        echo "    local subcommand=\"\$1\"" >> "$plugin_dir/main.zsh"
        echo "    shift" >> "$plugin_dir/main.zsh"
        echo "    log_event \"${plugin_name}\" \"Executing subcommand: \$subcommand with args: \$*\" \"INFO\"" >> "$plugin_dir/main.zsh"
        echo "    case \"\$subcommand\" in" >> "$plugin_dir/main.zsh"
        echo "        greet)" >> "$plugin_dir/main.zsh"
        echo "            echo \"Hello from ${plugin_name}!\"" >> "$plugin_dir/main.zsh"
        echo "            ;;" >> "$plugin_dir/main.zsh"
        echo "        status)" >> "$plugin_dir/main.zsh"
        echo "            echo \"${plugin_name} is active.\"" >> "$plugin_dir/main.zsh"
        echo "            ;;" >> "$plugin_dir/main.zsh"
        echo "        configure)" >> "$plugin_dir/main.zsh"
        echo "            echo \"Configuring ${plugin_name} with args: \$*\"" >> "$plugin_dir/main.zsh"
        echo "            ;;" >> "$plugin_dir/main.zsh"
        echo "        *)" >> "$plugin_dir/main.zsh"
        echo "            echo \"Unknown subcommand: \$subcommand\"" >> "$plugin_dir/main.zsh"
        echo "            echo \"Supported: greet, status, configure\"" >> "$plugin_dir/main.zsh"
        echo "            ;;" >> "$plugin_dir/main.zsh"
        echo "    esac" >> "$plugin_dir/main.zsh"
        echo "}" >> "$plugin_dir/main.zsh"
        echo "" >> "$plugin_dir/main.zsh"
        echo "# Execute main function with arguments" >> "$plugin_dir/main.zsh"
        echo "${plugin_name}_main \"\$@\"" >> "$plugin_dir/main.zsh"
        chmod +x "$plugin_dir/main.zsh"
        log_message "Created main.zsh for plugin '$plugin_name'."

        # Create plugin.conf with sections, including [repo]
        echo "[general]" > "$plugin_dir/plugin.conf"
        echo "name=${plugin_name}" >> "$plugin_dir/plugin.conf"
        echo "description=A powerful plugin to demonstrate extended configuration with commands." >> "$plugin_dir/plugin.conf"
        echo "version=1.0.0" >> "$plugin_dir/plugin.conf"
        echo "author=YourName" >> "$plugin_dir/plugin.conf"
        echo "enabled=true" >> "$plugin_dir/plugin.conf"
        echo "" >> "$plugin_dir/plugin.conf"
        echo "[commands]" >> "$plugin_dir/plugin.conf"
        echo "greet=echo \"Hello from ${plugin_name}!\"" >> "$plugin_dir/plugin.conf"
        echo "status=${plugin_name}_status" >> "$plugin_dir/plugin.conf"
        echo "configure=${plugin_name}_configure" >> "$plugin_dir/plugin.conf"
        echo "" >> "$plugin_dir/plugin.conf"
        echo "[drivers]" >> "$plugin_dir/plugin.conf"
        echo "sqlite=enabled" >> "$plugin_dir/plugin.conf"
        echo "" >> "$plugin_dir/plugin.conf"
        echo "[database]" >> "$plugin_dir/plugin.conf"
        echo "driver=sqlite" >> "$plugin_dir/plugin.conf"
        echo "db_file=\${MYBASH_DIR}/db/mybash.db" >> "$plugin_dir/plugin.conf"
        echo "" >> "$plugin_dir/plugin.conf"
        echo "[settings]" >> "$plugin_dir/plugin.conf"
        echo "log_level=info" >> "$plugin_dir/plugin.conf"
        echo "timeout=30" >> "$plugin_dir/plugin.conf"
        echo "auto_update=true" >> "$plugin_dir/plugin.conf"
        echo "" >> "$plugin_dir/plugin.conf"
        echo "[dependencies]" >> "$plugin_dir/plugin.conf"
        echo "required_packages=sqlite3" >> "$plugin_dir/plugin.conf"
        echo "optional_packages=" >> "$plugin_dir/plugin.conf"
        echo "" >> "$plugin_dir/plugin.conf"
        echo "[repo]" >> "$plugin_dir/plugin.conf"
        echo "source=local" >> "$plugin_dir/plugin.conf"
        echo "url=" >> "$plugin_dir/plugin.conf"  # Empty by default, to be filled if repo-based

        log_message "Created plugin.conf for plugin '$plugin_name'."
        echo "Plugin '$plugin_name' created successfully at $plugin_dir."
    }

    show_create_plugin_help() {
        echo "Usage: myb create-plugin <plugin_name>"
        echo "Creates a new plugin with a basic structure in $MYBASH_DIR/plugins/<plugin_name>."
    }

    # ==============================
    # INSTALL PLUGIN
    # ==============================
    install_plugin() {
        local plugin_name="$1"
        local plugin_dir="$PLUGINS_DIR/$plugin_name"
        local config_file="$plugin_dir/plugin.conf"

        # Validate plugin name
        if [[ -z "$plugin_name" ]]; then
            log_message "Error: Plugin name is required."
            print_colored red "Error: Plugin name is required."
            show_install_plugin_help
            return 1
        fi

        # Check if plugin exists locally; if not, attempt to fetch from repo
        if [[ ! -d "$plugin_dir" ]]; then
            log_message "Plugin '$plugin_name' not found in $PLUGINS_DIR. Checking repo configuration..."
            print_colored yellow "Plugin '$plugin_name' not found locally. Checking for repository source..."

            # Temporary config file to check for repo info if plugin isn't local yet
            local temp_conf="$MYBASH_DIR/config/plugins.conf"
            local repo_source=""
            local repo_url=""
            if [[ ! -f "$temp_conf" || ! $(grep -q "^$plugin_name=" "$temp_conf") ]]; then
                log_message "Error: Plugin '$plugin_name' not registered in $temp_conf and not found locally."
                print_colored red "Error: Plugin '$plugin_name' not found and no repo info available in $temp_conf."
                return 1
            fi

            # Read repo info from plugins.conf (assuming we'll store repo info there initially)
            repo_source=$(grep "^$plugin_name.source=" "$temp_conf" | cut -d'=' -f2)
            repo_url=$(grep "^$plugin_name.url=" "$temp_conf" | cut -d'=' -f2)

            # If no repo info in temp_conf, assume local unless specified later
            if [[ -z "$repo_source" ]]; then
                log_message "Error: Plugin '$plugin_name' not found locally and no repo source specified."
                print_colored red "Error: Plugin '$plugin_name' not found and no repository specified."
                return 1
            fi

            # Handle repository cloning based on source
            if [[ "$repo_source" == "github" && -n "$repo_url" ]]; then
                log_message "Cloning plugin '$plugin_name' from GitHub: $repo_url..."
                print_colored blue "Cloning plugin '$plugin_name' from $repo_url..."
                git clone "$repo_url" "$plugin_dir" >>"$LOG_FILE" 2>&1 || {
                    log_message "Error: Failed to clone repository from $repo_url."
                    print_colored red "Error: Failed to clone plugin from $repo_url. Check $LOG_FILE."
                    return 1
                }
                log_message "Successfully cloned '$plugin_name' from $repo_url."
                print_colored green "Successfully cloned '$plugin_name'."
            else
                log_message "Error: Unsupported repo source '$repo_source' or missing URL for '$plugin_name'."
                print_colored red "Error: Invalid or missing repo configuration for '$plugin_name'."
                return 1
            fi
        fi

        # Verify config file exists after cloning or if local
        if [[ ! -f "$config_file" ]]; then
            log_message "Error: 'plugin.conf' not found for plugin '$plugin_name'."
            print_colored red "Error: Missing plugin.conf for '$plugin_name'."
            return 1
        fi

        # Read [repo] section from plugin.conf to confirm or update source
        local repo_source=$(grep "^source=" "$config_file" | cut -d'=' -f2)
        local repo_url=$(grep "^url=" "$config_file" | cut -d'=' -f2)
        if [[ "$repo_source" != "local" && -n "$repo_url" ]]; then
            log_message "Plugin '$plugin_name' specifies a repo source: $repo_source ($repo_url)."
            # Optionally update plugins.conf with repo info if needed
        fi

        # Register plugin in plugins.conf
        local plugins_conf="$MYBASH_DIR/config/plugins.conf"
        if grep -q "^$plugin_name=" "$plugins_conf"; then
            sed -i "s/^$plugin_name=.*/$plugin_name=true/" "$plugins_conf"
            log_message "Updated plugin '$plugin_name' status to 'true' in $plugins_conf."
        else
            echo "$plugin_name=true" >> "$plugins_conf"
            if [[ -n "$repo_source" && "$repo_source" != "local" ]]; then
                echo "$plugin_name.source=$repo_source" >> "$plugins_conf"
                echo "$plugin_name.url=$repo_url" >> "$plugins_conf"
            fi
            log_message "Registered plugin '$plugin_name' in $plugins_conf."
        fi

        # Store plugin info in SQLite
        update_or_insert_config "plugin_$plugin_name" "$plugin_dir"
        load_plugin "$plugin_name"
        log_message "Plugin '$plugin_name' installed successfully."
        print_colored green "Plugin '$plugin_name' installed successfully."
    }

    show_install_plugin_help() {
        echo "Usage: myb install-plugin <plugin_name>"
        echo "Installs a plugin from a local directory or clones it from a specified repository."
        echo "If the plugin is not found locally, it checks $MYBASH_DIR/config/plugins.conf for repo info."
    }