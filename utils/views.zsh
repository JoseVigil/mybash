#!/bin/zsh

    source "$MYBASH_DIR/core/logger.zsh"

    tree_view() {
        log_event "tree_view" "Displaying directory tree" "INFO"
        if [[ "$OSTYPE" == "darwin"* ]]; then
            tree -L 2
        elif [[ "$OSTYPE" == "linux-gnu"* ]]; then
            if command -v tree &>/dev/null; then
                tree -L 2
            else
                log_event "tree_view" "Tree utility not installed" "ERROR"
                echo "Tree utility not installed. Install it with 'sudo apt install tree' or 'brew install tree'."
            fi
        else
            log_event "tree_view" "Unsupported OS" "ERROR"
            echo "Tree view is not supported on this OS."
        fi
    }

    mybash_tree() {
        log_event "mybash_tree" "Displaying MyBash directory structure" "INFO"
        if [[ "$OSTYPE" == "darwin"* || "$OSTYPE" == "linux-gnu"* ]]; then
            echo "MyBash Directory Structure:"
            tree "$MYBASH_DIR" -L 2
        else
            log_event "mybash_tree" "Unsupported OS" "ERROR"
            echo "Tree view is not supported on this OS."
        fi
    }

    list_windows() {
        log_event "list_windows" "Listing tmux windows" "INFO"
        echo "Open windows in the current terminal session:"
        tmux list-windows 2>/dev/null || {
            log_event "list_windows" "No tmux sessions found" "INFO"
            echo "No tmux sessions found."
        }
    }

    focus_window() {
        local window="$1"
        if [[ -z "$window" ]]; then
            log_event "focus_window" "No window number provided" "ERROR"
            echo "Usage: focus <window_number>"
            return 1
        fi
        log_event "focus_window" "Focusing window $window" "INFO"
        tmux select-window -t "$window" 2>/dev/null || {
            log_event "focus_window" "Window $window not found" "ERROR"
            echo "Window $window not found."
        }
    }

    tmux_layout() {
        log_event "tmux_layout" "Starting MyBash tmux layout" "INFO"
        tmux new-session -d -s mybash
        tmux split-window -h
        tmux split-window -v -t 0
        tmux send-keys -t 0 "myb" C-m
        tmux send-keys -t 1 "tail -f $LOG_FILE" C-m
        tmux send-keys -t 2 "echo 'Notes pane'" C-m
        tmux attach-session -t mybash
    }