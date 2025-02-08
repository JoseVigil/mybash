# Tab completion for bkm
_bkm_completion() {
    local bookmarks
    bookmarks=$(bookmark list_bookmark_names 2>/dev/null)
    reply=(${(ps:\n:)bookmarks})
}
compctl -K _bkm_completion bkm

# Bookmark function
bkm() {
    if [[ $# -eq 0 ]]; then
        bookmark go
    else
        bookmark "$@"
    fi
}
