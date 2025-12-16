#!/bin/bash
# Day 22: Array Operations
# This script stores a list of servers, pings each one,
# saves the result in an associative array,
# and prints a report of UP vs DOWN servers.

# -----------------------------
# 1. Store server list in an array
# -----------------------------
servers=("8.8.8.8" "1.1.1.1" "localhost" "192.0.2.1")

# -----------------------------
# 2. Declare an associative array
# -----------------------------
declare -A server_status

echo "Pinging servers..."
echo "-------------------"

# -----------------------------
# 3. Ping each server and store result
# -----------------------------
for server in "${servers[@]}"; do
    # Ping once (-c 1) and wait max 2 seconds (-W 2)
    if ping -c 1 -W 2 "$server" &> /dev/null; then
        server_status["$server"]="UP"
        echo "$server is UP"
    else
        server_status["$server"]="DOWN"
        echo "$server is DOWN"
    fi
done

echo
echo "Server Status Report"
echo "===================="

# -----------------------------
# 4. Print report: UP vs DOWN
# -----------------------------
up_count=0
down_count=0

for server in "${!server_status[@]}"; do
    if [[ "${server_status[$server]}" == "UP" ]]; then
        ((up_count++))
    else
        ((down_count++))
    fi
done

echo "Total Servers : ${#servers[@]}"
echo "UP Servers    : $up_count"
echo "DOWN Servers  : $down_count"

echo
echo "Detailed Report:"
for server in "${!server_status[@]}"; do
    echo "$server -> ${server_status[$server]}"
done
