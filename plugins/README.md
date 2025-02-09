# Plugins for MyBash

To create a new plugin:
1. Add a new file with a `.zsh` extension in this directory.
2. Define your functions or commands in the file.
3. The plugin will be automatically loaded when MyBash starts.

Example:
\`\`\`bash
# Plugin Example: Fine-tuning for LLMs
llm_finetune() {
    echo "Running fine-tuning for LLMs..."
    # Add your fine-tuning logic here
}
\`\`\`
