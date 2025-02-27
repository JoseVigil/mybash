# Plugins in MyBash

Plugins in MyBash allow extending the system's functionality in a modular way. Each plugin should be contained in its own folder within the `plugins` directory.

## Creating a Plugin
To create a plugin, follow these steps:

1. **Create the Plugin Folder**
   - Navigate to the `plugins` directory:
     ```bash
     cd $MYBASH_DIR/plugins
     ```
   - Create a new folder with the name of your plugin:
     ```bash
     mkdir my_plugin
     ```

2. **Plugin Structure**
   - Inside the plugin folder, create a `main.zsh` file. This file will serve as the entry point for your plugin.
   - Example minimal structure:
     ```
     plugins/
     └── my_plugin/
         └── main.zsh
     ```

3. **Implement Functionality**
   - In the `main.zsh` file, define the functions or commands you want to add to the system. For example:
     ```zsh
     # main.zsh
     my_plugin_function() {
         echo "Hello from my_plugin!"
     }
     ```

4. **Register the Plugin**
   - Ensure the plugin is enabled in the configuration file `config/plugins.conf`. Add a line with the plugin name and its status:
     ```
     my_plugin=true
     ```

5. **Restart MyBash**
   - After creating the plugin, restart MyBash to load it:
     ```bash
     source ~/.zshrc
     ```

6. **Test the Plugin**
   - Verify that the plugin works correctly by running its commands or functions.

## Additional Considerations
- **Naming Conventions**: Use descriptive names for your plugins and functions to avoid conflicts.
- **Compatibility**: Ensure your plugin is compatible with different operating systems if necessary.
- **Testing**: Before distributing a plugin, test it thoroughly to ensure it works as expected.

## Support
If you have questions or issues creating a plugin, consult the official MyBash documentation or contact the support team.
