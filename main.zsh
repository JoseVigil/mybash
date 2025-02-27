#!/bin/zsh

    # ==============================
    # VERIFY ZSH ENVIRONMENT
    # ==============================
    if [[ -z "$ZSH_VERSION" ]]; then
        echo "Error: mybash requires Zsh. Please run this script using Zsh."
        exit 1
    fi

    autoload -Uz compinit
    compinit

    if ! type compdef &>/dev/null; then
        echo "Warning: 'compdef' is not available. Autocompletion will not work."
    fi

    # ==============================
    # AVOID MULTIPLE LOAD
    # ==============================
    if [[ -n "$MYBASH_MAIN_LOADED" ]]; then
        return
    fi
    export MYBASH_MAIN_LOADED=true

    # ==============================
    # LOAD PATH FROM path.conf
    # ==============================
    load_path_from_conf() {
        local path_conf="/opt/mybash/path.conf"
        if [[ -f "$path_conf" ]]; then
            MYBASH_DIR=$(grep '^MYBASH_DIR=' "$path_conf" | cut -d'=' -f2)
            export MYBASH_DIR
            echo "Mybash running from: $MYBASH_DIR"
        else
            echo "Error: path.conf not found at $path_conf."
            exit 1
        fi
    }
    load_path_from_conf  

    # ==============================
    # LOAD GLOBAL VARIABLES
    # ==============================
    if [[ -f "$MYBASH_DIR/global.zsh" ]]; then
        source "$MYBASH_DIR/global.zsh"
    else
        echo "Error: Global variables file not found at $MYBASH_DIR/global.zsh."
        exit 1
    fi

    # ==============================
    # LOAD LOGGER
    # ==============================
    if [[ -f "$MYBASH_DIR/core/logger.zsh" ]]; then
        source "$MYBASH_DIR/core/logger.zsh"
    else
        echo "Error: Logger file not found at $MYBASH_DIR/core/logger.zsh."
        exit 1
    fi     

    # ==============================
    # LOAD CORE SCRIPTS
    # ==============================
    if [[ -f "$MYBASH_DIR/core/loader.zsh" ]]; then
        source "$MYBASH_DIR/core/loader.zsh"
        load_core_scripts
    else
        echo "Error: Loader script 'loader.zsh' not found."
        exit 1
    fi

    # ==============================
    # RUN TEST
    # ==============================

    # Function to handle the 'test' command
    run_tests() {
        TEST_SCRIPT="$MYBASH_DIR/utils/test.zsh"
        if [[ -f "$TEST_SCRIPT" ]]; then
            echo "Running tests..."
            bash "$TEST_SCRIPT"
        else
            echo "Error: Test script not found at $TEST_SCRIPT."
            log_message "Error: Test script not found at $TEST_SCRIPT."
            exit 1
        fi
    }

    # ==============================
    # COMMAND HANDLERS
    # ==============================

    # Validate and execute cmd_main
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

    # Validate and execute bkm_main
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

    # ==============================
    # INTERACTIVE SHELL
    # ==============================

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
                if [[ ${(k)PLUGIN_COMMANDS} =~ "$module_or_cmd\." ]]; then
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

    # ==============================
    # PYTHON ENTRY POINT
    # ==============================

    execute_mypy() {
        if [[ -f "$MYBASH_DIR/tools/mypy.zsh" ]]; then
            log_event "mypy" "Executing mypy with arguments: $*" "INFO"
            source "$MYBASH_DIR/tools/mypy.zsh"
            mypy "$@"
        else
            log_event "mypy" "Error: mypy.zsh not found at $MYBASH_DIR/tools/mypy.zsh" "ERROR"
            echo "Error: MyPy system not found. Please check your installation."
            exit 1
        fi
    }
        
    # ==============================
    # MAIN LOGIC
    # ==============================
    case "$1" in
        test)
            run_tests "$@"
        ;;        
        help)
            show_help
            ;;
        mypy)
           execute_mypy "${@:2}"
        ;;
        help-ext)
            show_ext_help
            ;;
        backup)
            create_backup
            ;;
        uninstall)
            uninstall
            ;;
        dependencies)
            case "$2" in
                check)
                    list_dependencies
                    ;;
                install)
                    install_dependencies
                    ;;
                *)
                    show_dependencies_help
                    ;;
            esac
            ;;
        symlinks)
            create_symlinks
            ;;
        zshrc)
            add_to_zshrc
            ;;
        data)
            create_data_directories
            ;;
        test)
            run_tests
            ;;
        cmd)
            execute_cmd_main "$@"
            ;;
        bkm)
            execute_bkm_main "$@"
            ;;       
        env)
            case "$2" in
                create)
                    env_create "$3"
                    ;;
                activate)
                    env_activate "$3"
                    ;;
                list)
                    env_list
                    ;;
                delete)
                    env_delete "$3"
                    ;;
                *)
                    show_env_help
                    ;;
            esac
            ;;
        conda)
            case "$2" in
                create)
                    conda_create "$3"
                    ;;
                activate)
                    conda_activate "$3"
                    ;;
                list)
                    conda_list
                    ;;
                delete)
                    conda_delete "$3"
                    ;;
                *)
                    show_conda_help
                    ;;
            esac
            ;;
        create-plugin)
            if [[ -z "$2" ]]; then
                echo "Error: Plugin name is required."
                show_create_plugin_help
                exit 1
            fi
            create_plugin "$2"
            ;;
        install-plugin)
            if [[ -z "$2" ]]; then
                echo "Error: Plugin name is required."
                show_install_plugin_help
                exit 1
            fi
            install_plugin "$2"
            ;;
        *)
            if [[ -z "$1" ]]; then
                return 0
            else
                echo "Unknown command: $1"
                show_help
                exit 1
            fi
        ;;
    esac