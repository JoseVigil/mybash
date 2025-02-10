#!/bin/bash

# Load .env file if it exists
ENV_FILE="$HOME/repos/mybash/.env"
if [[ -f "$ENV_FILE" ]]; then
    source "$ENV_FILE"
fi

# Variables
MYBASH_DIR="${MYBASH_DIR:-$HOME/repos/mybash}"
MYBASH_DATA_DIR="${MYBASH_DATA_DIR:-$HOME/Documents/mybash}"
LOG_DIR="$MYBASH_DATA_DIR/log"
TEST_LOG="$LOG_DIR/test.log"

# Ensure the log directory exists
mkdir -p "$LOG_DIR"

# Function to log test results
log_test_result() {
    echo "$(date '+%Y-%m-%d %H:%M:%S') - $1" >> "$TEST_LOG"
}

# Clear previous test results
echo "" > "$TEST_LOG"

# Run all commands as tests and log results
run_tests() {
    echo "Running tests..."

    # Test: mybash help
    echo "Testing command: mybash help..."
    output=$(mybash help 2>&1)
    if [[ $? -eq 0 ]]; then
        log_test_result "✅ Test passed: 'mybash help' executed successfully."
    else
        log_test_result "❌ Test failed: 'mybash help' encountered an error. Output: $output"
    fi

    # Test: mybash backup
    echo "Testing command: mybash backup..."
    output=$(mybash backup 2>&1)
    if [[ $? -eq 0 ]]; then
        log_test_result "✅ Test passed: 'mybash backup' executed successfully."
    else
        log_test_result "❌ Test failed: 'mybash backup' encountered an error. Output: $output"
    fi

    # Test: mybash dependencies
    echo "Testing command: mybash dependencies..."
    output=$(mybash dependencies 2>&1)
    if [[ $? -eq 0 ]]; then
        log_test_result "✅ Test passed: 'mybash dependencies' executed successfully."
    else
        log_test_result "❌ Test failed: 'mybash dependencies' encountered an error. Output: $output"
    fi

    # Test: mybash symlinks
    echo "Testing command: mybash symlinks..."
    output=$(mybash symlinks 2>&1)
    if [[ $? -eq 0 ]]; then
        log_test_result "✅ Test passed: 'mybash symlinks' executed successfully."
    else
        log_test_result "❌ Test failed: 'mybash symlinks' encountered an error. Output: $output"
    fi

    # Test: mybash zshrc
    echo "Testing command: mybash zshrc..."
    output=$(mybash zshrc 2>&1)
    if [[ $? -eq 0 ]]; then
        log_test_result "✅ Test passed: 'mybash zshrc' executed successfully."
    else
        log_test_result "❌ Test failed: 'mybash zshrc' encountered an error. Output: $output"
    fi

    # Test: mybash data
    echo "Testing command: mybash data..."
    output=$(mybash data 2>&1)
    if [[ $? -eq 0 ]]; then
        log_test_result "✅ Test passed: 'mybash data' executed successfully."
    else
        log_test_result "❌ Test failed: 'mybash data' encountered an error. Output: $output"
    fi

    # Test: mybash cmd
    echo "Testing command: mybash cmd..."
    output=$(mybash cmd 2>&1)
    if [[ $? -eq 0 ]]; then
        log_test_result "✅ Test passed: 'mybash cmd' executed successfully."
    else
        log_test_result "❌ Test failed: 'mybash cmd' encountered an error. Output: $output"
    fi

    # Test: mybash bkm
    echo "Testing command: mybash bkm..."
    output=$(mybash bkm 2>&1)
    if [[ $? -eq 0 ]]; then
        log_test_result "✅ Test passed: 'mybash bkm' executed successfully."
    else
        log_test_result "❌ Test failed: 'mybash bkm' encountered an error. Output: $output"
    fi

    echo "All tests completed. Check results in $TEST_LOG."
}

# Run the tests
run_tests