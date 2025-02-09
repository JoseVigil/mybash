# Tools for MyBash

Tools are reusable utilities that can be used by the core or plugins. They provide general-purpose functionality.

To create a new tool:
1. Add a new file with a `.zsh` extension in this directory.
2. Define your functions or commands in the file.
3. The tool will be automatically loaded when MyBash starts.

Example:
\`\`\`bash
# Tool Example: Tree View
tree_view() {
    tree -L 2
}
\`\`\`
