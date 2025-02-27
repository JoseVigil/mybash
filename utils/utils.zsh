#!/bin/zsh

    source "$MYBASH_DIR/global.zsh"
    source "$MYBASH_DIR/core/logger.zsh"

    cpwd() {
        log_event "cpwd" "Copying current path to clipboard" "INFO"
        pwd | pbcopy
        echo "Copied current path to clipboard: $(pwd)"
    }

    largefiles() {
        local count=${1:-10}
        log_event "largefiles" "Listing $count largest files" "INFO"
        find . -type f -exec du -h {} + | sort -rh | head -n "$count"
    }

    opendir() {
        log_event "opendir" "Opening directory explorer" "INFO"
        if [[ "$OSTYPE" == "darwin"* ]]; then
            open .
        elif [[ "$OSTYPE" == "linux-gnu"* ]]; then
            xdg-open .
        else
            log_event "opendir" "Unsupported OS" "ERROR"
            echo "File explorer utility not supported on this OS."
            return 1
        fi
    }

    mkcd() {
        log_event "mkcd" "Creating and entering directory $1" "INFO"
        mkdir -p "$1" && cd "$1"
    }

    myip() {
        log_event "myip" "Retrieving IP address" "INFO"
        if [[ "$OSTYPE" == "darwin"* ]]; then
            local wifi_interface=$(networksetup -listallhardwareports | awk '/Wi-Fi/{getline; print $2}')
            if [[ -z "$wifi_interface" ]]; then
                log_event "myip" "Wi-Fi interface not found" "ERROR"
                echo "Wi-Fi interface not found."
                return 1
            fi
            local ip_address=$(ifconfig "$wifi_interface" | awk '/inet /{print $2}')
        elif [[ "$OSTYPE" == "linux-gnu"* ]]; then
            local ip_address=$(ip addr show | grep 'inet ' | grep -v '127.0.0.1' | awk '{print $2}' | cut -d '/' -f 1)
        else
            log_event "myip" "Unsupported OS" "ERROR"
            echo "IP address utility not supported on this OS."
            return 1
        fi
        if [[ -z "$ip_address" ]]; then
            log_event "myip" "No IP address found" "ERROR"
            echo "No IP address found."
            return 1
        fi
        echo "IP Address: $ip_address"
    }

    load_file() {
        local file="$1"
        if [[ -z "$file" ]]; then
            log_event "load_file" "No file provided" "ERROR"
            echo "Usage: load_file <file>"
            return 1
        fi
        if [[ ! -f "$file" ]]; then
            log_event "load_file" "File '$file' not found" "ERROR"
            echo "Error: File '$file' not found."
            return 1
        fi
        log_event "load_file" "Loading file $file" "INFO"
        cat "$file"
    }

    extract_functions_from_file() {
        local file="$1"
        if [[ ! -f "$file" ]]; then
            log_event "extract_functions_from_file" "File '$file' not found" "ERROR"
            echo "Error: Archivo no encontrado: $file"
            return 1
        fi
        log_event "extract_functions_from_file" "Extracting functions from $file" "INFO"
        grep -E '^\s*(function\s+[a-zA-Z_][a-zA-Z0-9_]*|[a-zA-Z_][a-zA-Z0-9_]*\(\))' "$file" | sed -E 's/\(\)\s*\{//' | sed -E 's/function //'
    }

    extract_functions_from_dir() {
        local dir="$1"
        if [[ ! -d "$dir" ]]; then
            log_event "extract_functions_from_dir" "Directory '$dir' not found" "ERROR"
            echo "Error: Directorio no encontrado: $dir"
            return 1
        fi
        log_event "extract_functions_from_dir" "Extracting functions from directory $dir" "INFO"
        for file in "$dir"/*.sh "$dir"/*.zsh; do
            [[ -f "$file" ]] || continue
            echo "Archivo: $file"
            extract_functions_from_file "$file"
            echo "---------------------------------"
        done
    }