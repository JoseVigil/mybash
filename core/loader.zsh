#!/bin/zsh

MYBASH_DATABASE_LOADED=false
MYBASH_CORE_LOADED=false
MYBASH_PLUGINS_LOADED=false

load_core_scripts() {
    if [[ "$MYBASH_CORE_LOADED" == true ]]; then
        [[ -n "$MYBASH_DEBUG" || -n "$MYBASH_CHECK_MODE" ]] && log_message "Core scripts already loaded. Skipping."
        return 0
    fi
    CORE_SCRIPTS=(
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
    for script in "${CORE_SCRIPTS[@]}"; do
        if [[ -f "$script" ]]; then
            source "$script" && [[ -n "$MYBASH_DEBUG" || -n "$MYBASH_CHECK_MODE" ]] && log_message "Core script '$script' loaded successfully."
        else
            [[ -n "$MYBASH_DEBUG" || -n "$MYBASH_CHECK_MODE" ]] && log_message "Warning: Core script '$script' not found. Continuing."
        fi
    done
    MYBASH_CORE_LOADED=true
    [[ -n "$MYBASH_DEBUG" || -n "$MYBASH_CHECK_MODE" ]] && log_message "Core scripts loading completed."
}

load_plugins() {
    if [[ "$MYBASH_PLUGINS_LOADED" == true ]]; then
        [[ -n "$MYBASH_DEBUG" || -n "$MYBASH_CHECK_MODE" ]] && log_message "Plugins already loaded. Skipping."
        return 0
    fi
    local plugins_conf="$MYBASH_DIR/config/plugins.conf"
    if [[ ! -f "$plugins_conf" ]]; then
        [[ -n "$MYBASH_DEBUG" || -n "$MYBASH_CHECK_MODE" ]] && log_message "Warning: Plugins config file not found at $plugins_conf. No plugins loaded."
        return 0
    fi
    while IFS='=' read -r name plugin_status; do
        [[ -z "$name" || "$name" =~ ^# ]] && continue
        if [[ "$plugin_status" == "true" ]]; then
            local plugin_script="$PLUGINS_DIR/$name/$name.zsh"
            if [[ -f "$plugin_script" ]]; then
                source "$plugin_script" && [[ -n "$MYBASH_DEBUG" || -n "$MYBASH_CHECK_MODE" ]] && log_message "Plugin '$name' loaded successfully from $plugin_script."
            else
                [[ -n "$MYBASH_DEBUG" || -n "$MYBASH_CHECK_MODE" ]] && log_message "Warning: Plugin script '$plugin_script' not found for '$name'."
            fi
        fi
    done < "$plugins_conf"
    MYBASH_PLUGINS_LOADED=true
    [[ -n "$MYBASH_DEBUG" || -n "$MYBASH_CHECK_MODE" ]] && log_message "Plugins loading completed."
}