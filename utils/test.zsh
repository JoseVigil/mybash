#!/bin/zsh

    # Script to run automated tests for the MyBash system

    # Prevent reload if sourced
    if [[ "${BASH_SOURCE[0]}" != "${0}" ]]; then
        # This file was loaded as a module, do not run the tests
        return
    fi

    # Load global variables and logger
    source "$MYBASH_DIR/global.zsh"
    source "$MYBASH_DIR/core/logger.zsh"

    # Logging directory and file
    TEST_LOG="$MYBASH_LOGS_DIR/test_results.log"

    # Ensure log directory exists
    mkdir -p "$MYBASH_LOGS_DIR" || {
        echo "Error: Failed to create log directory at $MYBASH_LOGS_DIR"
        exit 1
    }

    # Helper function to run a test
    run_test() {
        local test_name="$1"
        local command="$2"
        local expected_output="$3"
        local expected_exit_code="$4"

        log_event "test" "Running test: $test_name" "INFO"
        print_colored blue "Running test: $test_name"
        output=$($command 2>&1)
        exit_code=$?

        if [[ "$exit_code" -eq "$expected_exit_code" && "$output" == "$expected_output" ]]; then
            log_event "test" "[PASS] $test_name" "INFO"
            print_colored green "[PASS] $test_name"
        else
            log_event "test" "[FAIL] $test_name - Exit code: $exit_code, Output: $output" "ERROR"
            print_colored red "[FAIL] $test_name - Exit code: $exit_code, Output: $output"
        fi
    }

    # Test cases
    run_tests() {
        echo "Running MyBash tests..."

        # Test 1: Verify command existence
        run_test "myb executable" "which myb" "/usr/local/bin/myb" 0

        # Test 2: Help command
        run_test "help command" "myb help | grep -q 'Available commands'" "Available commands:" 0

        # Test 3: Backup command (adjusted for macOS output)
        run_test "backup command" "myb backup" "Backup created successfully at $MYBASH_BACKUP_DIR/mybash_backup_*.tar.gz" 0

        # Test 4: Invalid command
        run_test "invalid command" "myb invalid_cmd" "Unknown command: invalid_cmd" 1

        # Test 5: Interactive shell entry
        run_test "interactive shell" "echo 'exit' | myb | grep -q 'Entering MyBash interactive shell'" "Entering MyBash interactive shell" 0

        # Test 6: Database initialization (check table existence)
        run_test "database config table" "sqlite3 $DB_FILE 'SELECT name FROM sqlite_master WHERE type=\"table\" AND name=\"config\";'" "config" 0

        # Test summary
        local passed=$(grep -c "\[PASS\]" "$TEST_LOG")
        local failed=$(grep -c "\[FAIL\]" "$TEST_LOG")
        print_colored blue "----------------------------------------"
        print_colored blue "Test Summary:"
        print_colored green "Passed: $passed"
        print_colored red "Failed: $failed"
        print_colored blue "----------------------------------------"

        if [[ "$failed" -gt 0 ]]; then
            print_colored red "Failed Tests:"
            grep "\[FAIL\]" "$TEST_LOG"
            exit 1
        else
            print_colored green "All tests passed successfully."
            exit 0
        fi
    }

    # Run tests if executed directly
    if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
        # First verify the system
        source "$MYBASH_DIR/utils/verify.zsh"
        verify_system || {
            print_colored red "System verification failed. Aborting tests."
            exit 1
        }
        run_tests
    fi