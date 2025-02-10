# tools/py/modules/log.py
import os
import sys
import psutil

def get_metadata(command_name, args):
    """
    Captures metadata about the current environment and process.
    :param command_name: Name of the command being executed.
    :param args: Arguments passed to the command.
    :return: A dictionary containing metadata.
    """
    # Get environment variables (filtering for MYBASH-related variables)
    env_vars = {k: v for k, v in os.environ.items() if k.startswith("MYBASH_")}

    # Get current process information
    current_process = psutil.Process(os.getpid())
    process_info = {
        "pid": current_process.pid,
        "name": current_process.name(),
        "cmdline": current_process.cmdline(),
    }

    # Combine all metadata
    metadata = {
        "command_name": command_name,
        "args": args,
        "env_vars": env_vars,
        "process_info": process_info,
    }
    return str(metadata)

if __name__ == "__main__":
    # Parse arguments from the command line
    command_name = sys.argv[1]
    args = sys.argv[2:]
    print(get_metadata(command_name, args))