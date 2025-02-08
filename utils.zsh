# Utility: Copy current directory path to clipboard
cpwd() {
    pwd | pbcopy
    echo "Copied current path to clipboard: $(pwd)"
}

# Utility: Find the 10 largest files in the current directory
largefiles() {
    find . -type f -exec du -h {} + | sort -rh | head -n 10
}

# Utility: Open the current directory in Finder
opendir() {
    open .
}

# Utility: Create a directory and navigate into it
mkcd() {
    mkdir -p "$1" && cd "$1"
}

# Utility: Display the Wi-Fi IP address
myip() {
    local wifi_interface=$(networksetup -listallhardwareports | awk '/Wi-Fi/{getline; print $2}')
    if [[ -z "$wifi_interface" ]]; then
        echo "Wi-Fi interface not found."
        return 1
    fi

    local ip_address=$(ifconfig "$wifi_interface" | awk '/inet /{print $2}')
    if [[ -z "$ip_address" ]]; then
        echo "No Wi-Fi IP address found."
        return 1
    fi

    echo "Wi-Fi IP Address: $ip_address"
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
