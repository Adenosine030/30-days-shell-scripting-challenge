#!/bin/bash
# Day 30: Complete DevOps Toolkit
# Author: Ademola
# Description: A modular DevOps toolkit combining monitoring, backups,
# logs, security audits, and automation.

set -e

REPORT_DIR="$HOME/devops_reports"
BACKUP_DIR="$HOME/devops_backups"
LOG_FILE="/var/log/syslog"

mkdir -p "$REPORT_DIR" "$BACKUP_DIR"

# -----------------------------
# Utility Functions
# -----------------------------
pause() {
    read -rp "Press Enter to continue..."
}

header() {
    clear
    echo "======================================"
    echo "        DEVOPS TOOLKIT - DAY 30        "
    echo "======================================"
    echo
}

# -----------------------------
# 1. System Monitoring
# -----------------------------
system_monitoring() {
    header
    echo "📊 System Monitoring"
    echo "-------------------"
    echo "CPU Usage:"
    top -bn1 | grep "Cpu(s)"

    echo
    echo "Memory Usage:"
    free -h

    echo
    echo "Disk Usage:"
    df -h /

    pause
}

# -----------------------------
# 2. Service Management
# -----------------------------
service_management() {
    header
    read -rp "Enter service name (e.g., ssh, docker): " service
    echo "1) Start"
    echo "2) Stop"
    echo "3) Restart"
    read -rp "Choose action: " action

    case $action in
        1) sudo systemctl start "$service" ;;
        2) sudo systemctl stop "$service" ;;
        3) sudo systemctl restart "$service" ;;
        *) echo "Invalid option" ;;
    esac

    systemctl status "$service" --no-pager
    pause
}

# -----------------------------
# 3. Backup Operations
# -----------------------------
backup_operations() {
    header
    TIMESTAMP=$(date +%F_%H-%M-%S)
    BACKUP_FILE="$BACKUP_DIR/backup_$TIMESTAMP.tar.gz"

    read -rp "Enter directory to back up: " target
    tar -czf "$BACKUP_FILE" "$target"

    echo "✅ Backup created: $BACKUP_FILE"
    pause
}

# -----------------------------
# 4. Log Analysis
# -----------------------------
log_analysis() {
    header
    echo "📜 Last 10 System Errors"
    echo "----------------------"
    grep -i "error" "$LOG_FILE" | tail -10 || echo "No errors found"
    pause
}

# -----------------------------
# 5. Deployment Automation (Simulated)
# -----------------------------
deployment_automation() {
    header
    echo "🚀 Deployment Automation"
    echo "-----------------------"
    echo "Pulling latest code..."
    git pull origin main || echo "Not a git repo"

    echo "Restarting application service (example)..."
    echo "(Simulated deployment)"
    pause
}

# -----------------------------
# 6. Security Audit
# -----------------------------
security_audit() {
    header
    REPORT="$REPORT_DIR/security_$(date +%F).txt"

    {
        echo "Security Audit Report - $(date)"
        echo "--------------------------------"

        echo "Users with sudo access:"
        getent group sudo

        echo
        echo "World-writable files:"
        find / -xdev -type f -perm -0002 2>/dev/null | head -10

        echo
        echo "SUID files:"
        find / -perm -4000 -type f 2>/dev/null | head -10
    } > "$REPORT"

    echo "🔐 Security report generated: $REPORT"
    pause
}

# -----------------------------
# 7. Generate Reports
# -----------------------------
generate_reports() {
    header
    REPORT="$REPORT_DIR/system_report_$(date +%F).txt"

    {
        echo "System Report - $(date)"
        echo "----------------------"
        uname -a
        echo
        df -h
        echo
        free -h
    } > "$REPORT"

    echo "📄 Report saved: $REPORT"
    pause
}

# -----------------------------
# Main Menu
# -----------------------------
while true; do
    header
    echo "1) System Monitoring"
    echo "2) Service Management"
    echo "3) Backup Operations"
    echo "4) Log Analysis"
    echo "5) Deployment Automation"
    echo "6) Security Audit"
    echo "7) Generate Reports"
    echo "8) Exit"
    echo
    read -rp "Select an option: " choice

    case $choice in
        1) system_monitoring ;;
        2) service_management ;;
        3) backup_operations ;;
        4) log_analysis ;;
        5) deployment_automation ;;
        6) security_audit ;;
        7) generate_reports ;;
        8) echo "👋 Exiting DevOps Toolkit"; exit 0 ;;
        *) echo "Invalid option"; sleep 1 ;;
    esac
done
