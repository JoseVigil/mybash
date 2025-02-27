# tools/py/modules/log.py
import os
import sys
import psutil

def get_metadata(command_name, args):
    """
    Captures metadata about the current environment and process.
    :param command_name: Name of the command being executed.
    :param args: Arguments passed to the command.
    :return: A formatted string containing metadata in a user-friendly way.
    """
    # Get environment variables (filtering for MYBASH-related variables)
    env_vars = {k: v for k, v in os.environ.items() if k.startswith("MYBASH_")}
    
    # Get current process information
    current_process = psutil.Process(os.getpid())
    process_info = {
        "PID": current_process.pid,
        "Process Name": current_process.name(),
        "Command Line": " ".join(current_process.cmdline()),
    }

    # Build a readable metadata string
    metadata = f"Command Name: {command_name}\n"
    metadata += f"Arguments: {' '.join(args)}\n\n"
    metadata += "Environment Variables:\n"
    for key, value in env_vars.items():
        metadata += f"  {key}: {value}\n"
    metadata += "\nProcess Information:\n"
    for key, value in process_info.items():
        metadata += f"  {key}: {value}\n"

    return metadata

if __name__ == "__main__":
    # Parse arguments from the command line
    command_name = sys.argv[1]
    args = sys.argv[2:]
    print(get_metadata(command_name, args))