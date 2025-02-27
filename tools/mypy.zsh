#!/bin/zsh

    # Tool: MyPy Bridge
    # This tool allows executing Python modules through the MyPy system

    source "$MYBASH_DIR/core/logger.zsh"

    mypy() {
        local module="$1"
        shift
        local args="$@"

        if [[ -z "$module" ]]; then
            log_event "mypy" "No module provided" "ERROR"
            echo "Usage: mypy <module_name> [args...]"
            return 1
        fi

        if [[ ! -f "$MYBASH_DIR/tools/py/modules/${module}.py" ]]; then
            log_event "mypy" "Module '${module}' not found" "ERROR"
            echo "Error: Module '${module}' not found in 'tools/py/modules/'."
            return 1
        fi

        local python_script="$MYBASH_DIR/tools/py/mypy.py"
        if [[ ! -f "$python_script" ]]; then
            log_event "mypy" "Python script not found at '$python_script'" "ERROR"
            echo "Error: Python system script not found at '$python_script'."
            return 1
        fi

        log_event "mypy" "Executing module: $module with args: $args" "INFO"
        echo "Executing Python module: $module"
        python3 "$python_script" "$module" $args
        local exit_code=$?
        log_event "mypy" "Module '$module' executed with exit code $exit_code" "INFO"
        return $exit_code
    }

    mypy "$@"