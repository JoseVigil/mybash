#!/bin/zsh

    # ==============================
    # GLOBAL VARIABLES
    # ==============================
    source "$MYBASH_DIR/global.zsh"

    # ==============================
    # AUTO-COMPLETION CONFIGURATION
    # ==============================

    # List of available commands for auto-completion
    MYBASH_COMMANDS=(
        "help" "backup" "dependencies" "symlinks" "zshrc" "data" "test" "cmd" "bkm" "sticky"
    )

    # Command-specific subcommands
    typeset -A CMD_SUBCOMMANDS
    CMD_SUBCOMMANDS["cmd"]="add remove list help"
    CMD_SUBCOMMANDS["bkm"]="add remove list help"
    CMD_SUBCOMMANDS["sticky"]="add remove list help"
    CMD_SUBCOMMANDS["env"]="create activate list delete"
    CMD_SUBCOMMANDS["conda"]="create activate list delete"

    # Autocompletion for mybash commands
    _mybash_completion() {
        local cur prev opts
        cur="${COMP_WORDS[COMP_CWORD]}"
        prev="${COMP_WORDS[COMP_CWORD-1]}"

        # Comandos de nivel superior (módulos)
        opts="help backup dependencies symlinks zshrc data test cmd bkm mypy env conda create-plugin install-plugin ${(@k)PLUGIN_COMMANDS}"

        case "$prev" in
            cmd) opts="${CMD_SUBCOMMANDS[cmd]}" ;;
            bkm) opts="${CMD_SUBCOMMANDS[bkm]}" ;;
            env) opts="${CMD_SUBCOMMANDS[env]}" ;;
            conda) opts="${CMD_SUBCOMMANDS[conda]}" ;;
            data|ml|viz|stats|nlp|ai|utils)
                # Obtener subcomandos del plugin
                opts=$(for k in ${(k)PLUGIN_COMMANDS}; do [[ "$k" =~ "^$prev\." ]] && echo "${k#$prev.}"; done)
                ;;
            *)
                opts="${(@k)PLUGIN_COMMANDS}"
                ;;
        esac

        COMPREPLY=( $(compgen -W "$opts" -- "$cur") )
    }

    if type compdef &>/dev/null; then
        compdef _mybash_completion myb  # Cambiado de 'mybash' a 'myb'
    else
        echo "Warning: 'compdef' is not available. Autocompletion will not work."
    fi

    # Register the auto-completion function
    if type compdef &>/dev/null; then
        compdef _mybash_completion mybash
    else
        echo "Warning: 'compdef' is not available. Autocompletion will not work."
    fi