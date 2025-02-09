# Core functionality
# Core functionality
core_init() {
    echo "Initializing MyBash Core..."
    source "$MYBASH_DIR/core/utils.zsh"
    source "$MYBASH_DIR/core/bkm.zsh"
    source "$MYBASH_DIR/core/cmd.zsh"
    source "$MYBASH_DIR/core/synch.zsh"
    source "$MYBASH_DIR/db/dbhelper.zsh"
    init_db
}
