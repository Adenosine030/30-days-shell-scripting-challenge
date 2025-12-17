#!/bin/bash
# Day 23: Error Handling
# This script demonstrates robust error handling in Bash:
# - Exits immediately on errors
# - Catches errors using trap
# - Logs errors with timestamps
# - Cleans up temporary files on exit
# - Sends a failure notification (simulated)

# -----------------------------
# 1. Exit immediately on error
# -----------------------------
set -e

# -----------------------------
# Global variables
# -----------------------------
LOG_FILE="$HOME/day23_error.log"
TEMP_FILE="/tmp/day23_temp_file.txt"

# -----------------------------
# Function: log error with timestamp
# -----------------------------
log_error() {
    local error_message="$1"
    echo "$(date '+%Y-%m-%d %H:%M:%S') ERROR: $error_message" >> "$LOG_FILE"
}

# -----------------------------
# Function: cleanup temp files
# -----------------------------
cleanup() {
    if [[ -f "$TEMP_FILE" ]]; then
        rm -f "$TEMP_FILE"
        echo "Temporary files cleaned up."
    fi
}

# -----------------------------
# Function: failure notification
# -----------------------------
send_notification() {
    # Simulated notification (email/Slack can be added later)
    echo "❌ Script failed! Check log file: $LOG_FILE"
}

# -----------------------------
# 2. Trap errors
# -----------------------------
trap 'log_error "Script failed at line $LINENO"; send_notification' ERR

# -----------------------------
# 4. Cleanup on exit (success or failure)
# -----------------------------
trap cleanup EXIT

# -----------------------------
# Main script logic
# -----------------------------

echo "Starting Day 23 error handling script..."

# Create temp file
echo "Temporary data" > "$TEMP_FILE"

# Simulate work
echo "Processing data..."

# ❌ Intentional error for demonstration
# Uncomment the next line to test error handling
# cat /non_existent_file

echo "Script completed successfully."
