#!/bin/zsh

[[ -n "$MYBASH_LOADER_LOADED" ]] && return 0
export MYBASH_LOADER_LOADED=true

load_plugins() {
    local plugins_conf="$MYBASH_DIR/config/plugins.conf"
    if [[ ! -f "$plugins_conf" ]]; then
        echo "Warning: No plugins.conf found at $plugins_conf. No plugins loaded."
        return 0
    fi

    while IFS='=' read -r plugin_name plugin_enabled; do
        [[ "$plugin_name" =~ "^#" || -z "$plugin_name" ]] && continue
        
        plugin_name=$(echo "$plugin_name" | sed 's/^[[:space:]]*//;s/[[:space:]]*$//')
        plugin_enabled=$(echo "$plugin_enabled" | sed 's/^[[:space:]]*//;s/[[:space:]]*$//')

        if [[ "$plugin_enabled" == "true" ]]; then
            local plugin_script="$PLUGINS_DIR/$plugin_name/$plugin_name.zsh"
            if [[ -f "$plugin_script" ]]; then
                source "$plugin_script"
                if [[ $? -ne 0 ]]; then
                    echo "Error: Failed to load plugin $plugin_name from $plugin_script."
                    exit 1
                fi
            else
                echo "Warning: Plugin script not found for $plugin_name at $plugin_script."
            fi
        fi
    done < "$plugins_conf"
}