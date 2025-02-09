# Utility functions
cpwd() {
    pwd | pbcopy
    echo "Copied current path to clipboard: $(pwd)"
}

largefiles() {
    local count=${1:-10}
    find . -type f -exec du -h {} + | sort -rh | head -n "$count"
}

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

mkcd() {
    mkdir -p "$1" && cd "$1"
}

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