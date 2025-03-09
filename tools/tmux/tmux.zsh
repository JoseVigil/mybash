#!/bin/zsh

source "$MYBASH_DIR/core/logger.zsh"

tmux_driver() {
    local cmd="$1"
    shift
    local args="$@"

    case "$cmd" in
        generate)
            local layout_name="${args:-mybash}"
            local output_file="$MYBASH_DIR/config/tmuxinator/${layout_name}.yml"
            log_message "INFO" "Generating tmux layout: $layout_name"

            echo "# Project name in tmuxinator" > "$output_file"
            echo "name: mybash" >> "$output_file"
            echo "root: $MYBASH_DIR" >> "$output_file"
            echo "" >> "$output_file"
            echo "windows:" >> "$output_file"
            echo "  - main:" >> "$output_file"
            echo "      layout: tiled" >> "$output_file"
            echo "      panes:" >> "$output_file"
            echo "        - zsh -c 'myb'" >> "$output_file"

            # Android window if device is connected
            if command -v adb &>/dev/null && adb devices 2>/dev/null | grep -q "device$"; then
                log_message "INFO" "Android device detected. Adding Android window."
                echo "  - android:" >> "$output_file"
                echo "      layout: main-vertical" >> "$output_file"
                echo "      panes:" >> "$output_file"
                echo "        - zsh -c 'myb android'" >> "$output_file"
                echo "        - zsh -c 'myb android logcat'" >> "$output_file"
            fi

            # Videos window
            echo "  - videos:" >> "$output_file"
            echo "      layout: main-vertical" >> "$output_file"
            echo "      panes:" >> "$output_file"
            echo "        - zsh -c 'myb videos'" >> "$output_file"

            # Logs window
            echo "  - logs:" >> "$output_file"
            echo "      layout: even-horizontal" >> "$output_file"
            echo "      panes:" >> "$output_file"
            echo "        - zsh -c 'tail -f \$MYBASH_LOGS_DIR/mybash.log'" >> "$output_file"
            echo "        - zsh -c 'tail -f \$MYBASH_DATA_HOME_DIR/logs/logcat.log'" >> "$output_file"

            log_message "INFO" "Tmux layout generated at $output_file"
            echo "Tmux layout generated at $output_file"
            ;;
        start)
            tmux_driver generate "mybash"
            start_mybash
            ;;
        *)
            echo "Usage: myb tmux [generate [layout_name] | start]"
            ;;
    esac
}

TOOL_DRIVER_COMMANDS[tmux]="tmux_driver"