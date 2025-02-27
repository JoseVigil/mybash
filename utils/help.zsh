#!/bin/zsh


    # Load logging functionality
    source "$MYBASH_DIR/core/logger.zsh"

    # ==============================
    # HELP FUNCTIONS
    # ==============================

    # General help message
    show_help() {
        echo "Usage: mybash [command]"
        echo ""
        echo "Available commands:"
        echo "  help             Show this help message."
        echo "  env              Manage virtual environments (create, activate, list, delete)."
        echo "  conda            Manage Conda environments (create, activate, list, delete)."
        echo "  backup           Create a backup of the mybash project."
        echo "  dependencies     Install or check required dependencies."
        echo "  symlinks         Create symbolic links for mybash commands."
        echo "  zshrc            Add main.zsh to ~/.zshrc."
        echo "  data             Create necessary data directories."
        echo "  test             Run automated tests."
        echo "  cmd              Execute custom commands."
        echo "  bkm              Execute bookmark-related commands."
        echo "  install-plugin   Install a plugin from a repository or local path."
    }

    # Extended help message
    show_ext_help() {
        echo "Usage: mybash [command]"
        echo ""
        echo "Available commands:"
        echo "  help             Show this help message with detailed descriptions."
        echo "                   Use 'mybash help' to display this list of commands."
        echo ""
        echo "  env              Manage virtual environments (create, activate, list, delete)."
        echo "                   - create: Create a new virtual environment with the specified name."
        echo "                             Usage: mybash env create <env_name>"
        echo "                   - activate: Activate an existing virtual environment by name."
        echo "                               Usage: mybash env activate <env_name>"
        echo "                   - list: List all available virtual environments."
        echo "                           Usage: mybash env list"
        echo "                   - delete: Delete a virtual environment by name."
        echo "                             Usage: mybash env delete <env_name>"
        echo ""
        echo "  conda            Manage Conda environments (create, activate, list, delete)."
        echo "                   - create: Create a new Conda environment with the specified name."
        echo "                             Usage: mybash conda create <env_name>"
        echo "                   - activate: Activate an existing Conda environment by name."
        echo "                               Usage: mybash conda activate <env_name>"
        echo "                   - list: List all available Conda environments."
        echo "                           Usage: mybash conda list"
        echo "                   - delete: Delete a Conda environment by name."
        echo "                             Usage: mybash conda delete <env_name>"
        echo ""
        echo "  backup           Create a backup of the mybash project."
        echo "                   This command creates a timestamped backup of the entire mybash directory,"
        echo "                   including configurations, plugins, and data files."
        echo "                   Usage: mybash backup"
        echo ""
        echo "  uninstall        Uninstall the mybash system completely."
        echo "                   This command removes all installed components, including symlinks, data directories,"
        echo "                   and configurations from the system."
        echo "                   Usage: mybash uninstall"
        echo ""
        echo "  dependencies     Install or check required dependencies."
        echo "                   - check: Verify that all required dependencies are installed."
        echo "                            Usage: mybash dependencies check"
        echo "                   - install: Install all required dependencies for the system."
        echo "                              Usage: mybash dependencies install"
        echo ""
        echo "  symlinks         Create symbolic links for mybash commands."
        echo "                   This command ensures that mybash commands are accessible globally by creating"
        echo "                   symbolic links in /usr/local/bin."
        echo "                   Usage: mybash symlinks"
        echo ""
        echo "  zshrc            Add main.zsh to ~/.zshrc."
        echo "                   This command ensures that mybash is loaded automatically when a new terminal session starts."
        echo "                   It adds a line to source main.zsh in the ~/.zshrc file."
        echo "                   Usage: mybash zshrc"
        echo ""
        echo "  data             Create necessary data directories."
        echo "                   This command creates directories required for storing logs, migrations, plugins, and other data."
        echo "                   Usage: mybash data"
        echo ""
        echo "  test             Run automated tests."
        echo "                   Execute the test suite to verify the functionality of the mybash system."
        echo "                   Usage: mybash test"
        echo ""
        echo "  cmd              Execute custom commands."
        echo "                   This command allows you to execute custom-defined commands implemented in the cmd.zsh script."
        echo "                   Usage: mybash cmd <command> [args...]"
        echo ""
        echo "  bkm              Execute bookmark-related commands."
        echo "                   This command provides functionality for managing bookmarks, such as adding, listing, or deleting bookmarks."
        echo "                   Usage: mybash bkm <command> [args...]"
        echo ""
        echo "  sticky           Manage sticky notes (create, list, edit, delete)."
        echo "                   This command allows you to manage sticky notes, which can be used for reminders or quick notes."
        echo "                   - create: Create a new sticky note."
        echo "                             Usage: mybash sticky create <note_content>"
        echo "                   - list: List all existing sticky notes."
        echo "                           Usage: mybash sticky list"
        echo "                   - edit: Edit an existing sticky note by ID."
        echo "                           Usage: mybash sticky edit <note_id> <new_content>"
        echo "                   - delete: Delete a sticky note by ID."
        echo "                             Usage: mybash sticky delete <note_id>"
        echo ""
        echo "  create-plugin    Create a new plugin skeleton."
        echo "                   This command generates a basic structure for a new plugin, including a main.zsh file and README."
        echo "                   Usage: mybash create-plugin <plugin_name>"
        echo ""
        echo "  install-plugin   Install a plugin from a repository or local path."
        echo "                   This command installs a plugin into the mybash system, either from a remote repository or a local directory."
        echo "                   Usage: mybash install-plugin <plugin_name_or_path>"
        echo ""
        echo "For more details, use 'mybash [command] --help'."
    }

    # Help for specific commands
    show_env_help() {
        echo "Usage: mybash env [create|activate|list|delete] <name>"
    }

    show_conda_help() {
        echo "Usage: mybash conda [create|activate|list|delete] <name>"
    }

    show_dependencies_help() {
        echo "Usage: mybash dependencies [check|install]"
    }

    show_install_plugin_help() {
        echo "Usage: mybash install-plugin <repo_url> <plugin_name> [is_private]"
    }