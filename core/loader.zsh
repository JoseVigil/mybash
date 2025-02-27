#!/bin/zsh

    # Flags para evitar recarga
    MYBASH_DATABASE_LOADED=false
    MYBASH_CORE_LOADED=false
    MYBASH_PLUGINS_LOADED=false

    # ==============================
    # LOAD CORE SCRIPTS
    # ==============================
    load_core_scripts() {
        if [[ "$MYBASH_CORE_LOADED" == true ]]; then
            [[ -n "$MYBASH_DEBUG" || -n "$MYBASH_CHECK_MODE" ]] && log_message "Core scripts already loaded. Skipping."
            return 0
        fi

        # Lista predeterminada de scripts esenciales
        CORE_SCRIPTS=(
            "$MYBASH_DIR/main.zsh"
            "$MYBASH_DIR/core/cmd.zsh"
            "$MYBASH_DIR/core/bkm.zsh"
            "$MYBASH_DIR/core/env.zsh"
            "$MYBASH_DIR/core/synch.zsh"
            "$MYBASH_DIR/core/completion.zsh"
            "$MYBASH_DIR/core/func.zsh"
            "$MYBASH_DIR/utils/utils.zsh"
            "$MYBASH_DIR/utils/help.zsh"
            "$MYBASH_DIR/db/dbhelper.zsh"
        )

        # Cargar scripts adicionales desde un archivo de configuración opcional
        local config_file="$MYBASH_DIR/config/core_scripts.conf"
        if [[ -f "$config_file" ]]; then
            while IFS= read -r script; do
                [[ -z "$script" || "$script" == \#* ]] && continue
                CORE_SCRIPTS+=("$MYBASH_DIR/$script")
            done < "$config_file"
            [[ -n "$MYBASH_DEBUG" || -n "$MYBASH_CHECK_MODE" ]] && log_message "Loaded additional core scripts from $config_file."
        fi

        # Carga condicional de test.zsh
        if [[ "$MYBASH_LOAD_TESTS" == "true" ]]; then
            CORE_SCRIPTS+=("$MYBASH_DIR/utils/test.zsh")
        fi

        # Cargar cada script con manejo de errores
        for script in "${CORE_SCRIPTS[@]}"; do
            if [[ -f "$script" ]]; then
                source "$script" && [[ -n "$MYBASH_DEBUG" || -n "$MYBASH_CHECK_MODE" ]] && log_message "Core script '$script' loaded successfully."
            else
                [[ -n "$MYBASH_DEBUG" || -n "$MYBASH_CHECK_MODE" ]] && log_message "Warning: Core script '$script' not found. Continuing."
                [[ -n "$MYBASH_DEBUG" || -n "$MYBASH_CHECK_MODE" ]] && echo "Warning: Core script '$script' not found. Check logs."
            fi
        done
        MYBASH_CORE_LOADED=true
        [[ -n "$MYBASH_DEBUG" || -n "$MYBASH_CHECK_MODE" ]] && log_message "Core scripts loading completed."
    }

    # ==============================
    # LOAD PLUGINS
    # ==============================
    load_plugins() {
        if [[ "$MYBASH_PLUGINS_LOADED" == true ]]; then
            log_message "Plugins already loaded. Skipping."
            return 0
        fi
        typeset -gA PLUGIN_COMMANDS  # Array global associating para comandos
        if [[ -f "$PLUGIN_CONF" ]]; then
            while IFS='=' read -r plugin_name plugin_status; do
                plugin_name=$(echo "$plugin_name" | tr -d '[:space:]')
                plugin_status=$(echo "$plugin_status" | tr -d '[:space:]')
                [[ -z "$plugin_name" || "$plugin_name" == \#* ]] && continue
                if [[ "$plugin_status" == "true" ]]; then
                    load_plugin "$plugin_name"
                    # Leer comandos desde plugin.conf
                    local conf_file="$MYBASH_DIR/plugins/$plugin_name/plugin.conf"
                    if [[ -f "$conf_file" ]]; then
                        while IFS='=' read -r key value; do
                            key=$(echo "$key" | tr -d '[:space:]')
                            value=$(echo "$value" | tr -d '[:space:]')
                            if [[ "$key" == "["*"]" ]]; then
                                current_section="${key//[\[\]]/}"
                            elif [[ "$current_section" == "commands" && -n "$key" ]]; then
                                PLUGIN_COMMANDS["$plugin_name.$key"]="$value"
                            fi
                        done < "$conf_file"
                    fi
                fi
            done < "$PLUGIN_CONF"
            log_message "Plugins loading completed."
        else
            log_message "Warning: Plugin configuration file not found at $PLUGIN_CONF."
            echo "No plugins loaded (config missing)."
        fi
        
        local drivers=""
        while IFS='=' read -r key value; do
            if [[ "$current_section" == "drivers" && "$value" == "enabled" ]]; then
                drivers="$drivers $key"
            fi
        done < "$conf_file"
        log_message "Enabled drivers for $plugin_name: $drivers"
        MYBASH_PLUGINS_LOADED=true
    }

    # ==============================
    # LOAD DEPENDENCIES FROM CONFIG FILE
    # ==============================
    load_dependencies() {
        local os_type="$1"
        DEPENDENCIES=()
        if [[ ! -f "$DEPENDENCIES_CONF" ]]; then
            log_message "Error: Dependencies file not found at $DEPENDENCIES_CONF."
            echo "Error: Missing dependencies config. Check $DEPENDENCIES_CONF."
            exit 1
        fi
        local current_os=""
        while IFS='=' read -r package details; do
            [[ -z "$package" || "$package" =~ ^[[:space:]]*# ]] && continue
            package=$(echo "$package" | tr -d '[:space:]')
            details=$(echo "$details" | tr -d '[:space:]')
            if [[ "$package" == \[*\] ]]; then
                current_os="${package//[\[\]]/}"
            elif [[ -n "$package" && "$current_os" == "$os_type" ]]; then
                DEPENDENCIES+=("$package=$details")
            fi
        done < "$DEPENDENCIES_CONF"
        log_message "Loaded dependencies for $os_type: ${DEPENDENCIES[*]}"
    }