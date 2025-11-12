#!/bin/bash
# ===============================
# Day 7: Functions Challenge
# ===============================
# File: day07_functions.sh
echo "Enter your name"
read NAME
# Function 1: greet
greet() {
    echo "==============================="
    echo "👋 Welcome $NAME to the System Info Script!"
    echo "==============================="
    echo
}

# Function 2: system_info
system_info() {
    echo "💻 SYSTEM INFORMATION"
    echo "-------------------------------"
    echo "CPU Info:"
    lscpu | grep "Model name"
    echo

    echo "Memory Usage:"
    free -h | awk '/Mem/{print "Used: "$3" | Free: "$4}'
    echo

    echo "Disk Usage:"
    df -h --total | grep total
    echo "-------------------------------"
    echo
    echo "🌐 Hostname:"
    echo "  $(hostname)"

    echo "⏰ Uptime:"
    echo "  $(uptime -p)"
}

# Function 3: goodbye
goodbye() {
    echo "==============================="
    echo "👋 Goodbye! Keep scripting daily 💪"
    echo "==============================="
    echo
}

# Main script execution
greet
system_info
goodbye
