#!/bin/zsh

    ENV_DIR="$HOME/Documents/mybash/environments"
    MYBASH_DIR="${MYBASH_DIR:-$HOME/repos/mybash}"
    MYBASH_DATA_DIR="${MYBASH_DATA_DIR:-$HOME/Documents/mybash}"
    ENV_DIR="$MYBASH_DATA_DIR/environments"
    CONDA_ENV_DIR="$MYBASH_DATA_DIR/conda_envs"

    # Load logging functionality
    source "$MYBASH_DIR/core/logger.zsh"

    # ==============================
    # ENVIRONMENT MANAGEMENT
    # ==============================

    # Function to create a new environment
    env_create() {
        local env_name="$1"
        if [[ -z "$env_name" ]]; then
            echo "Usage: mybash env create <name>"
            return 1
        fi

        local env_path="$ENV_DIR/$env_name"
        if [[ -d "$env_path" ]]; then
            echo "Error: Environment '$env_name' already exists."
            return 1
        fi

        log_event "env_create" "Creating environment '$env_name'..."
        python3 -m venv "$env_path" || {
            log_event "env_create" "Failed to create environment '$env_name'."
            echo "Error: Failed to create environment '$env_name'."
            return 1
        }
        log_event "env_create" "Environment '$env_name' created successfully."
        echo "Environment '$env_name' created successfully."
    }

    # Function to activate an environment
    env_activate() {
        local env_name="$1"
        if [[ -z "$env_name" ]]; then
            echo "Usage: mybash env activate <name>"
            return 1
        fi

        local env_path="$ENV_DIR/$env_name/bin/activate"
        if [[ ! -f "$env_path" ]]; then
            echo "Error: Environment '$env_name' not found."
            return 1
        fi

        log_event "env_activate" "Activating environment '$env_name'..."
        source "$env_path"
        echo "Environment '$env_name' activated."
    }

    # Function to list all environments
    env_list() {
        log_event "env_list" "Listing environments..."
        if [[ ! -d "$ENV_DIR" || -z "$(ls -A "$ENV_DIR")" ]]; then
            echo "No environments found."
            return 0
        fi

        echo "Available environments:"
        for env in "$ENV_DIR"/*; do
            if [[ -d "$env" ]]; then
                echo "  $(basename "$env")"
            fi
        done
    }

    # Function to delete an environment
    env_delete() {
        local env_name="$1"
        if [[ -z "$env_name" ]]; then
            echo "Usage: mybash env delete <name>"
            return 1
        fi

        local env_path="$ENV_DIR/$env_name"
        if [[ ! -d "$env_path" ]]; then
            echo "Error: Environment '$env_name' not found."
            return 1
        fi

        log_event "env_delete" "Deleting environment '$env_name'..."
        rm -rf "$env_path"
        log_event "env_delete" "Environment '$env_name' deleted successfully."
        echo "Environment '$env_name' deleted successfully."
    }

    # ==============================
    # CONDA ENVIRONMENT MANAGEMENT
    # ==============================

    # Function to create a new Conda environment
    conda_create() {
        local env_name="$1"
        if [[ -z "$env_name" ]]; then
            echo "Usage: mybash conda create <name>"
            return 1
        fi
        if conda info --envs | grep -q "$env_name"; then
            echo "Error: Conda environment '$env_name' already exists."
            return 1
        fi
        log_event "conda_create" "Creating Conda environment '$env_name'..."
        conda create -n "$env_name" python=3.12 -y || {
            log_event "conda_create" "Failed to create Conda environment '$env_name'."
            echo "Error: Failed to create Conda environment '$env_name'."
            return 1
        }
        log_event "conda_create" "Conda environment '$env_name' created successfully."
        echo "Conda environment '$env_name' created successfully."
    }

    # Function to activate a Conda environment
    conda_activate() {
        local env_name="$1"
        if [[ -z "$env_name" ]]; then
            echo "Usage: mybash conda activate <name>"
            return 1
        fi
        if ! conda info --envs | grep -q "$env_name"; then
            echo "Error: Conda environment '$env_name' not found."
            return 1
        fi
        log_event "conda_activate" "Activating Conda environment '$env_name'..."
        conda activate "$env_name" || {
            log_event "conda_activate" "Failed to activate Conda environment '$env_name'."
            echo "Error: Failed to activate Conda environment '$env_name'."
            return 1
        }
        echo "Conda environment '$env_name' activated."
    }

    # Function to list all Conda environments
    conda_list() {
        log_event "conda_list" "Listing Conda environments..."
        conda info --envs
    }

    # Function to delete a Conda environment
    conda_delete() {
        local env_name="$1"
        if [[ -z "$env_name" ]]; then
            echo "Usage: mybash conda delete <name>"
            return 1
        fi
        if ! conda info --envs | grep -q "$env_name"; then
            echo "Error: Conda environment '$env_name' not found."
            return 1
        fi
        log_event "conda_delete" "Deleting Conda environment '$env_name'..."
        conda remove -n "$env_name" --all -y || {
            log_event "conda_delete" "Failed to delete Conda environment '$env_name'."
            echo "Error: Failed to delete Conda environment '$env_name'."
            return 1
        }
        log_event "conda_delete" "Conda environment '$env_name' deleted successfully."
        echo "Conda environment '$env_name' deleted successfully."
    }