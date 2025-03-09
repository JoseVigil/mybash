#!/bin/zsh

# Ensure the script is running in Zsh
if [[ -z "$ZSH_VERSION" ]]; then
    echo "Error: mybash requires Zsh. Please run this script using Zsh."
    exit 1
fi

autoload -Uz compinit
compinit

if [[ -o interactive && -n "$MYBASH_MAIN_LOADED" ]]; then
    return
fi
export MYBASH_MAIN_LOADED=true

load_path_from_conf() {
    local path_conf="/opt/mybash/path.conf"
    if [[ -f "$path_conf" ]]; then
        MYBASH_DIR=$(grep '^MYBASH_DIR=' "$path_conf" | cut -d'=' -f2)
        export MYBASH_DIR
    else
        MYBASH_DIR="$(cd "$(dirname "$0")" && pwd)"
        export MYBASH_DIR
    fi
}
load_path_from_conf  

if [[ -f "$MYBASH_DIR/global.zsh" ]]; then
    source "$MYBASH_DIR/global.zsh"
else
    echo "Error: Global variables file not found at $MYBASH_DIR/global.zsh."
    exit 1
fi

# Define global arrays for commands
typeset -A -g PLUGIN_COMMANDS
typeset -A -g TOOL_DRIVER_COMMANDS

# Load logger first and verify
if [[ -f "$MYBASH_DIR/core/logger.zsh" ]]; then
    source "$MYBASH_DIR/core/logger.zsh"
    if ! typeset -f log_message > /dev/null; then
        echo "Error: log_message not defined after sourcing $MYBASH_DIR/core/logger.zsh."
        exit 1
    fi
    echo "Debug: log_message defined after sourcing logger.zsh."
else
    echo "Error: Logger script not found at $MYBASH_DIR/core/logger.zsh."
    exit 1
fi

core_scripts=(
    "bkm.zsh"
    "cmd.zsh"
    "completion.zsh"
    "env.zsh"
    "func.zsh"
    "selfcheck.zsh"
)
for script in "${core_scripts[@]}"; do
    script_path="$MYBASH_DIR/core/$script"
    if [[ -f "$script_path" ]]; then
        source "$script_path"
        if [[ $? -ne 0 ]]; then
            echo "Error: Failed to source $script_path"
            exit 1
        fi
    else
        echo "Warning: Core script $script_path not found."
    fi
done

# Load tools from tools/drivers/
for tool_dir in "$MYBASH_DIR/tools/drivers/"*; do
    if [[ -d "$tool_dir" ]]; then
        tool_script="$tool_dir/$(basename "$tool_dir").zsh"
        if [[ -f "$tool_script" ]]; then
            source "$tool_script" >/dev/null 2>&1
            if [[ $? -ne 0 ]]; then
                echo "Error: Failed to source tool $tool_script"
                exit 1
            fi
        fi
    fi
done

# Load plugins from plugins.conf
if [[ -f "$MYBASH_DIR/core/loader.zsh" ]]; then
    source "$MYBASH_DIR/core/loader.zsh" >/dev/null 2>&1    
else
    echo "Error: Loader script 'loader.zsh' not found."
    exit 1
fi

execute_cmd_main() {
    if declare -F cmd_main &>/dev/null; then
        log_event "Executing cmd_main with arguments: $*"
        cmd_main "$@"
    else
        log_event "Error: 'cmd_main' function not found. Ensure cmd.zsh is loaded." "ERROR"
        echo "Error: 'cmd_main' function not found. Please check your installation."
        exit 1
    fi
}

execute_bkm_main() {
    if declare -F bkm_main &>/dev/null; then
        log_event "Executing bkm_main with arguments: $*"
        bkm_main "$@"
    else
        log_event "Error: 'bkm_main' function not found. Ensure bkm.zsh is loaded." "ERROR"
        echo "Error: 'bkm_main' function not found. Please check your installation."
        exit 1
    fi
}

interactive_shell() {
    echo "Entering MyBash interactive shell. Type 'exit' to quit."
    export MYB_CURRENT_MODULE=""
    while true; do
        if [[ -z "$MYB_CURRENT_MODULE" ]]; then
            echo -n "(myb) > "
        else
            echo -n "(myb:$MYB_CURRENT_MODULE) > "
        fi
        read -r input_command || break
        [[ "$input_command" == "exit" ]] && break
        set -- $input_command
        local module_or_cmd="$1"
        shift
        if [[ -n "$module_or_cmd" ]]; then
            if [[ -n "${TOOL_DRIVER_COMMANDS[$module_or_cmd]}" ]]; then
                eval "${TOOL_DRIVER_COMMANDS[$module_or_cmd]}" "$@"
            elif [[ ${(k)PLUGIN_COMMANDS} =~ "$module_or_cmd\." ]]; then
                MYB_CURRENT_MODULE="$module_or_cmd"
                if [[ -n "$1" ]]; then
                    local cmd_key="$module_or_cmd.$1"
                    if [[ -n "${PLUGIN_COMMANDS[$cmd_key]}" ]]; then
                        eval "${PLUGIN_COMMANDS[$cmd_key]}" "$@"
                    else
                        execute_mypy "$module_or_cmd" "$1" "$@"
                    fi
                fi
            elif [[ -n "$MYB_CURRENT_MODULE" ]]; then
                local cmd_key="$MYB_CURRENT_MODULE.$module_or_cmd"
                if [[ -n "${PLUGIN_COMMANDS[$cmd_key]}" ]]; then
                    eval "${PLUGIN_COMMANDS[$cmd_key]}" "$@"
                else
                    execute_mypy "$MYB_CURRENT_MODULE" "$module_or_cmd" "$@"
                fi
            else
                echo "Unknown module or command: $module_or_cmd"
            fi
        fi
    done
    echo "Exiting interactive shell."
}

execute_mypy() {
    if [[ -f "$MYBASH_DIR/tools/mypy.zsh" ]]; then
        log_event "mypy" "Executing mypy with arguments: $*" "INFO"
        source "$MYBASH_DIR/tools/mypy.zsh" >/dev/null 2>&1
        mypy "$@"
    else
        log_event "mypy" "Error: mypy.zsh not found at $MYBASH_DIR/tools/mypy.zsh" "ERROR"
        echo "Error: MyPy system not found. Please check your installation."
        exit 1
    fi
}

dependencies_main() {
    case "$1" in
        check) list_dependencies ;;
        install) install_dependencies ;;
        *) show_dependencies_help ;;
    esac
}

env_main() {
    case "$1" in
        create) env_create "$2" ;;
        activate) env_activate "$2" ;;
        list) env_list ;;
        delete) env_delete "$2" ;;
        *) show_env_help ;;
    esac
}

conda_main() {
    case "$1" in
        create) conda_create "$2" ;;
        activate) conda_activate "$2" ;;
        list) conda_list ;;
        delete) conda_delete "$2" ;;
        *) show_conda_help ;;
    esac
}

show_help() {
    echo "Usage: mybash [command]"
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
    echo "  plugin           Manage plugins (clone, create, install, uninstall)."
    echo "  start            Launch MyBash interface with tmuxinator."
    echo "Tool commands:"
    for tool in "${(k)TOOL_DRIVER_COMMANDS[@]}"; do
        echo "  $tool"
    done
    if [[ -n "${(k)PLUGIN_COMMANDS}" ]]; then
        echo "Plugin commands:"
        for key in "${(k)PLUGIN_COMMANDS[@]}"; do
            echo "  ${key%%.*} ${key#*.}    Run ${PLUGIN_COMMANDS[$key]}"
        done
    fi
}

unknown_command() {
    if [[ -z "$1" ]]; then
        interactive_shell
    else
        echo "Unknown command: $1"
        show_help
        exit 1
    fi
}

start_mybash() {
    echo "Starting MyBash interface with tmuxinator..."
    tmuxinator start mybash || {
        log_message "ERROR" "Failed to start tmuxinator. Ensure it is installed and mybash.yml exists."
        echo "Error: Failed to start tmuxinator. Ensure it is installed and mybash.yml exists."
        return 1
    }
}
 
if [[ $# -ge 2 ]]; then
    local cmd_key="$1.$2"
    if [[ -n "${PLUGIN_COMMANDS[$cmd_key]}" ]]; then
        eval "${PLUGIN_COMMANDS[$cmd_key]}" "${@:3}"
        exit 0
    fi
fi

case "$1" in
    help) show_help ;;
    mypy) execute_mypy "${@:2}" ;;
    help-ext) show_ext_help ;;
    backup) create_backup ;;
    uninstall) uninstall ;;
    dependencies) dependencies_main "${@:2}" ;;
    symlinks) create_symlinks ;;
    zshrc) add_to_zshrc ;;
    data) create_data_directories ;;
    cmd) execute_cmd_main "$@" ;;
    bkm) execute_bkm_main "$@" ;;
    env) env_main "${@:2}" ;;
    conda) conda_main "${@:2}" ;;
    plugin) 
        log_message "INFO" "Calling plugin_main with args: ${@:2}"
        plugin_main "${@:2}" 
        ;;
    start) start_mybash ;;
    *) 
        if [[ -n "${TOOL_DRIVER_COMMANDS[$1]}" ]]; then
            eval "${TOOL_DRIVER_COMMANDS[$1]}" "${@:2}"
        else
            unknown_command "$1"
        fi
        ;;
esac