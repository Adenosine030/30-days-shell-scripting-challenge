#!/bin/bash
# Day 24: Configuration Parser
# This script reads an INI config file, parses sections and key=value pairs,
# validates required fields, and uses the values in the script.

set -e

CONFIG_FILE="config.ini"

# -----------------------------
# Check if config file exists
# -----------------------------
if [[ ! -f "$CONFIG_FILE" ]]; then
    echo "ERROR: Config file '$CONFIG_FILE' not found."
    exit 1
fi

# -----------------------------
# Declare associative arrays
# -----------------------------
declare -A database
declare -A backup

current_section=""

# -----------------------------
# Read and parse config file
# -----------------------------
while IFS='=' read -r key value; do
    # Remove whitespace
    key=$(echo "$key" | xargs)
    value=$(echo "$value" | xargs)

    # Skip empty lines and comments
    [[ -z "$key" || "$key" == \#* || "$key" == \;* ]] && continue

    # Detect section headers
    if [[ "$key" =~ ^\[(.*)\]$ ]]; then
        current_section="${BASH_REMATCH[1]}"
        continue
    fi

    # Store values based on section
    case "$current_section" in
        database)
            database["$key"]="$value"
            ;;
        backup)
            backup["$key"]="$value"
            ;;
    esac
done < "$CONFIG_FILE"

# -----------------------------
# 3. Validate required fields
# -----------------------------
required_db_fields=("host" "port" "user")
required_backup_fields=("destination" "retention")

for field in "${required_db_fields[@]}"; do
    if [[ -z "${database[$field]}" ]]; then
        echo "ERROR: Missing database.$field in config file."
        exit 1
    fi
done

for field in "${required_backup_fields[@]}"; do
    if [[ -z "${backup[$field]}" ]]; then
        echo "ERROR: Missing backup.$field in config file."
        exit 1
    fi
done

# -----------------------------
# 4. Use config values
# -----------------------------
echo "Database Configuration"
echo "----------------------"
echo "Host : ${database[host]}"
echo "Port : ${database[port]}"
echo "User : ${database[user]}"

echo
echo "Backup Configuration"
echo "--------------------"
echo "Destination : ${backup[destination]}"
echo "Retention   : ${backup[retention]} days"

# Example usage
echo
echo "Simulating backup operation..."
echo "Backing up database on ${database[host]} to ${backup[destination]}"
