# Tab completion for cmd
_cmd_completion() {
    local bookmarks
    bookmarks=$(cut -d '=' -f 1 ~/.cmd_bookmarks 2>/dev/null)
    reply=(${(ps:\n:)bookmarks})
}
compctl -K _cmd_completion cmd

# Command bookmark function
cmd() {
    if [[ $# -eq 0 ]]; then
        /usr/local/bin/cmd list
    else
        /usr/local/bin/cmd "$@"
    fi
}
