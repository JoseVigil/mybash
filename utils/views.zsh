# Tool: Tree View
# This tool provides directory tree visualization.

# General tree view
tree_view() {
    if [[ "$OSTYPE" == "darwin"* ]]; then
        tree -L 2
    elif [[ "$OSTYPE" == "linux-gnu"* ]]; then
        if command -v tree &>/dev/null; then
            tree -L 2
        else
            echo "Tree utility not installed. Install it with 'sudo apt install tree' or 'brew install tree'."
        fi
    else
        echo "Tree view is not supported on this OS."
    fi
}

# MyBash-specific tree view
mybash_tree() {
    if [[ "$OSTYPE" == "darwin"* || "$OSTYPE" == "linux-gnu"* ]]; then
        echo "MyBash Directory Structure:"
        tree "$MYBASH_DIR" -L 2
    else
        echo "Tree view is not supported on this OS."
    fi
}