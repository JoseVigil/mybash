# Tool: MyPy Bridge
# This tool allows executing Python modules through the MyPy system.

# Function to execute a Python module
mypy() {
    local module="$1"
    shift  # Remove the first argument (module name)
    local args="$@"

    # Validate that a module name is provided
    if [[ -z "$module" ]]; then
        echo "Usage: mypy <module_name> [args...]"
        return 1
    fi

    # Validate that the module exists in tools/py/modules/
    if [[ ! -f "$MYBASH_DIR/tools/py/modules/${module}.py" ]]; then
        echo "Error: Module '${module}' not found in 'tools/py/modules/'."
        return 1
    fi

    # Validate that the main Python script exists
    local python_script="$MYBASH_DIR/tools/py/mypy.py"
    if [[ ! -f "$python_script" ]]; then
        echo "Error: Python system script not found at '$python_script'."
        return 1
    fi

    # Execute the Python module
    echo "Executing Python module: $module"
    python3 "$python_script" "$module" $args
}