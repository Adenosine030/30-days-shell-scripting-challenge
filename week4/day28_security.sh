#!/bin/bash
# Day 28: Security Audit Script
# Performs basic system security checks and generates a report

set -e

REPORT_FILE="$HOME/day28_security_report.txt"
DATE=$(date "+%Y-%m-%d %H:%M:%S")

echo "Security Audit Report" > "$REPORT_FILE"
echo "Generated on: $DATE" >> "$REPORT_FILE"
echo "===================================" >> "$REPORT_FILE"
echo >> "$REPORT_FILE"

#######################################
# 1. Check for users with empty passwords
#######################################
echo "[1] Users with empty passwords:" >> "$REPORT_FILE"
awk -F: '($2 == "") { print $1 }' /etc/shadow 2>/dev/null || echo "Permission denied" >> "$REPORT_FILE"
echo >> "$REPORT_FILE"

#######################################
# 2. List users with sudo privileges
#######################################
echo "[2] Users with sudo privileges:" >> "$REPORT_FILE"
getent group sudo | awk -F: '{ print $4 }' >> "$REPORT_FILE"
echo >> "$REPORT_FILE"

#######################################
# 3. Check for world-writable files
#######################################
echo "[3] World-writable files (top 10):" >> "$REPORT_FILE"
find / -xdev -type f -perm -0002 2>/dev/null | head -n 10 >> "$REPORT_FILE"
echo >> "$REPORT_FILE"

#######################################
# 4. Check SSH configuration
#######################################
echo "[4] SSH Security Settings:" >> "$REPORT_FILE"
SSH_CONFIG="/etc/ssh/sshd_config"

if [[ -f "$SSH_CONFIG" ]]; then
    grep -Ei "PermitRootLogin|PasswordAuthentication" "$SSH_CONFIG" >> "$REPORT_FILE"
else
    echo "SSH config file not found" >> "$REPORT_FILE"
fi
echo >> "$REPORT_FILE"

#######################################
# 5. Find files with SUID bit set
#######################################
echo "[5] Files with SUID bit set (top 10):" >> "$REPORT_FILE"
find / -xdev -perm -4000 -type f 2>/dev/null | head -n 10 >> "$REPORT_FILE"
echo >> "$REPORT_FILE"

#######################################
# 6. Report completion
#######################################
echo "===================================" >> "$REPORT_FILE"
echo "Security audit completed successfully." >> "$REPORT_FILE"

echo "✅ Security audit completed."
echo "📄 Report saved to: $REPORT_FILE"
