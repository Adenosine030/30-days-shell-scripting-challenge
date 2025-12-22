#!/bin/bash
# Day 27: System Monitoring Dashboard

trap "clear; echo 'Dashboard exited.'; exit" SIGINT

while true; do
    clear
    echo "===== SYSTEM DASHBOARD ====="
    date
    echo

    echo "CPU Usage:"
    top -bn1 | grep "Cpu(s)" | awk '{print $2 + $4 "%"}'
    echo

    echo "Memory Usage:"
    free -h | awk 'NR==2{print $3 "/" $2}'
    echo

    echo "Disk Usage:"
    df -h / | awk 'NR==2{print $5 " used"}'
    echo

    echo "Top 5 Processes:"
    ps -eo pid,comm,%cpu --sort=-%cpu | head -6
    echo

    echo "Network Stats:"
    ss -s | head -5
    echo

    echo "Last 5 System Errors:"
    journalctl -p err -n 5 2>/dev/null || echo "No access to journalctl"

    sleep 2
done
