#!/bin/zsh

# Tool: MyPy Bridge
# This tool allows executing Python modules through the MyPy system
# Can be used as a core tool (myb mypy <module>) or by plugins (myb <plugin> python <module>)

source "$MYBASH_DIR/core/logger.zsh"

mypy() {
    local module="$1"
    shift
    local args="$@"

    if [[ -z "$module" ]]; then
        log_message "ERROR" "No module provided"
        echo "Usage: myb mypy <module_name> [args...] or myb <plugin> python <module_name> [args...]"
        return 1
    fi

    # Check if called from a plugin (e.g., myb notes python <module>)
    if [[ -n "$MYB_CURRENT_MODULE" ]]; then
        local plugin_module_path="$MYBASH_DIR/plugins/$MYB_CURRENT_MODULE/python/${module}.py"
        if [[ -f "$plugin_module_path" ]]; then
            module_path="$plugin_module_path"
        else
            log_message "ERROR" "Module '${module}' not found for plugin '$MYB_CURRENT_MODULE'"
            echo "Error: Module '${module}' not found in 'plugins/$MYB_CURRENT_MODULE/python/'."
            return 1
        fi
    else
        # Core tool mode: use tools/py/modules/
        local core_module_path="$MYBASH_DIR/tools/py/modules/${module}.py"
        if [[ -f "$core_module_path" ]]; then
            module_path="$core_module_path"
        else
            log_message "ERROR" "Module '${module}' not found"
            echo "Error: Module '${module}' not found in 'tools/py/modules/'."
            return 1
        fi
    fi

    local python_script="$MYBASH_DIR/tools/py/mypy.py"
    if [[ ! -f "$python_script" ]]; then
        log_message "ERROR" "Python script not found at '$python_script'"
        echo "Error: Python system script not found at '$python_script'."
        return 1
    fi

    log_message "INFO" "Executing module: $module with args: $args from $module_path"
    echo "Executing Python module: $module"
    python3 "$python_script" "$module" $args
    local exit_code=$?
    log_message "INFO" "Module '$module' executed with exit code $exit_code"
    return $exit_code
}

TOOL_DRIVER_COMMANDS[mypy]="mypy"
export -f mypy