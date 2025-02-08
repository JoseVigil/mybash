# Utility: Copy current directory path to clipboard
cpwd() {
    if [[ "$OSTYPE" == "darwin"* ]]; then
        pwd | pbcopy
    elif [[ "$OSTYPE" == "linux-gnu"* ]]; then
        pwd | xclip -selection clipboard
    else
        echo "Clipboard utility not supported on this OS."
        return 1
    fi
    echo "Copied current path to clipboard: $(pwd)"
}

# Utility: Find the 10 largest files in the current directory
largefiles() {
    local count=${1:-10}
    find . -type f -not -path "./.git/*" -exec du -h {} + | sort -rh | head -n "$count"
}

# Utility: Open the current directory in Finder
opendir() {
    if [[ "$OSTYPE" == "darwin"* ]]; then
        open .
    elif [[ "$OSTYPE" == "linux-gnu"* ]]; then
        xdg-open .
    else
        echo "File explorer utility not supported on this OS."
        return 1
    fi
}

# Utility: Create a directory and navigate into it
mkcd() {
    if [[ -z "$1" ]]; then
        echo "Usage: mkcd <directory_name>"
        return 1
    fi
    mkdir -p "$1" && cd "$1"
}

# Utility: Display the Wi-Fi IP address
myip() {
    if [[ "$OSTYPE" == "darwin"* ]]; then
        local wifi_interface=$(networksetup -listallhardwareports | awk '/Wi-Fi/{getline; print $2}')
        if [[ -z "$wifi_interface" ]]; then
            echo "Wi-Fi interface not found."
            return 1
        fi
        local ip_address=$(ifconfig "$wifi_interface" | awk '/inet /{print $2}')
    elif [[ "$OSTYPE" == "linux-gnu"* ]]; then
        local ip_address=$(ip addr show | grep 'inet ' | grep -v '127.0.0.1' | awk '{print $2}' | cut -d '/' -f 1)
    else
        echo "IP address utility not supported on this OS."
        return 1
    fi

    if [[ -z "$ip_address" ]]; then
        echo "No IP address found."
        return 1
    fi
    echo "IP Address: $ip_address"
}

# Utility: Empty a file after confirmation
empty() {
    if [[ -z "$1" ]]; then
        echo "Usage: empty <filename>"
        return 1
    fi
    local file="$1"
    if [[ ! -f "$file" ]]; then
        echo "Error: File '$file' does not exist."
        return 1
    fi
    read -q "?Are you sure you want to empty '$file'? (y/n) "
    echo
    if [[ $? -eq 0 ]]; then
        > "$file"
        echo "File '$file' has been emptied."
    else
        echo "Operation canceled."
    fi
}
