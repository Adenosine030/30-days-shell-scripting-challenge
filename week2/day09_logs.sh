#!/bin/bash
#
# Day 9: Log File Analyzer
# Author: CloudDemigod
# Date: November 14, 2025
#
# This script analyzes log files for ERROR, WARNING, and INFO messages
# and provides a summary report with top errors

# Color codes for better output
RED='\033[0;31m'
YELLOW='\033[1;33m'
GREEN='\033[0;32m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Function to create a sample log file for testing
create_sample_log() {
    cat > sample.log << 'EOF'
2025-11-14 10:23:45 INFO Application started successfully
2025-11-14 10:24:12 WARNING Database connection pool is 80% full
2025-11-14 10:25:33 ERROR Failed to connect to database: Connection timeout
2025-11-14 10:26:01 INFO User login: john@example.com
2025-11-14 10:27:15 ERROR Failed to connect to database: Connection timeout
2025-11-14 10:28:22 WARNING High memory usage detected: 85%
2025-11-14 10:29:44 INFO Processing batch job #1234
2025-11-14 10:30:11 ERROR File not found: /var/data/config.json
2025-11-14 10:31:25 WARNING Disk space low on /dev/sda1
2025-11-14 10:32:33 INFO User logout: john@example.com
2025-11-14 10:33:17 ERROR Failed to connect to database: Connection timeout
2025-11-14 10:34:28 WARNING API response time exceeded threshold
2025-11-14 10:35:41 INFO Cache cleared successfully
2025-11-14 10:36:09 ERROR Permission denied: /etc/secure/keys
2025-11-14 10:37:23 WARNING Database connection pool is 80% full
2025-11-14 10:38:55 INFO Scheduled backup completed
2025-11-14 10:39:12 ERROR Failed to send email notification
2025-11-14 10:40:31 WARNING High CPU usage detected: 92%
2025-11-14 10:41:44 INFO API endpoint /users accessed
2025-11-14 10:42:17 ERROR Network timeout while connecting to external service
EOF
    echo -e "${GREEN}Sample log file created: sample.log${NC}"
}

# Function to print header
print_header() {
    echo -e "\n${BLUE}╔═══════════════════════════════════════════════════╗${NC}"
    echo -e "${BLUE}║          LOG FILE ANALYZER REPORT                 ║${NC}"
    echo -e "${BLUE}╔═══════════════════════════════════════════════════╗${NC}\n"
}

# Function to analyze log file
analyze_log() {
    local logfile=$1
    
    # Check if file exists
    if [ ! -f "$logfile" ]; then
        echo -e "${RED}Error: Log file '$logfile' not found!${NC}"
        echo -e "${YELLOW}Creating a sample log file for testing...${NC}\n"
        create_sample_log
        logfile="sample.log"
    fi
    
    print_header
    
    echo -e "${BLUE}Analyzing file: ${NC}$logfile"
    echo -e "${BLUE}File size: ${NC}$(du -h "$logfile" | cut -f1)"
    echo -e "${BLUE}Total lines: ${NC}$(wc -l < "$logfile")\n"
    
    # Count different log levels
    local error_count=$(grep -c "ERROR" "$logfile" 2>/dev/null || echo 0)
    local warning_count=$(grep -c "WARNING" "$logfile" 2>/dev/null || echo 0)
    local info_count=$(grep -c "INFO" "$logfile" 2>/dev/null || echo 0)
    
    # Print summary with colors
    echo -e "═══════════════════════════════════════════════════"
    echo -e "${GREEN}INFO messages:    ${NC}$info_count"
    echo -e "${YELLOW}WARNING messages: ${NC}$warning_count"
    echo -e "${RED}ERROR messages:   ${NC}$error_count"
    echo -e "═══════════════════════════════════════════════════\n"
    
    # Show top 5 most common errors
    if [ $error_count -gt 0 ]; then
        echo -e "${RED}Top 5 Most Common Errors:${NC}"
        echo -e "═══════════════════════════════════════════════════"
        grep "ERROR" "$logfile" | \
        awk '{for(i=4;i<=NF;i++) printf "%s ", $i; print ""}' | \
        sort | uniq -c | sort -rn | head -5 | \
        awk '{count=$1; $1=""; printf "  [%2d occurrences] %s\n", count, $0}'
        echo ""
    else
        echo -e "${GREEN}No errors found in the log file!${NC}\n"
    fi
    
    # Show top 5 most common warnings
    if [ $warning_count -gt 0 ]; then
        echo -e "${YELLOW}Top 5 Most Common Warnings:${NC}"
        echo -e "═══════════════════════════════════════════════════"
        grep "WARNING" "$logfile" | \
        awk '{for(i=4;i<=NF;i++) printf "%s ", $i; print ""}' | \
        sort | uniq -c | sort -rn | head -5 | \
        awk '{count=$1; $1=""; printf "  [%2d occurrences] %s\n", count, $0}'
        echo ""
    fi
    
    # Calculate percentages
    local total=$((error_count + warning_count + info_count))
    if [ $total -gt 0 ]; then
        echo -e "${BLUE}Message Distribution:${NC}"
        echo -e "═══════════════════════════════════════════════════"
        printf "  INFO:    %5.1f%%\n" $(echo "scale=1; ($info_count * 100) / $total" | bc)
        printf "  WARNING: %5.1f%%\n" $(echo "scale=1; ($warning_count * 100) / $total" | bc)
        printf "  ERROR:   %5.1f%%\n" $(echo "scale=1; ($error_count * 100) / $total" | bc)
        echo -e "═══════════════════════════════════════════════════\n"
    fi
    
    # Show recent errors (last 3)
    if [ $error_count -gt 0 ]; then
        echo -e "${RED}Most Recent Errors (Last 3):${NC}"
        echo -e "═══════════════════════════════════════════════════"
        grep "ERROR" "$logfile" | tail -3 | while read line; do
            echo -e "  ${RED}•${NC} $line"
        done
        echo ""
    fi
    
    # Overall health status
    echo -e "${BLUE}Overall Health Status:${NC}"
    echo -e "═══════════════════════════════════════════════════"
    if [ $error_count -eq 0 ] && [ $warning_count -eq 0 ]; then
        echo -e "  ${GREEN}✓ EXCELLENT${NC} - No issues detected"
    elif [ $error_count -eq 0 ] && [ $warning_count -lt 5 ]; then
        echo -e "  ${GREEN}✓ GOOD${NC} - Few warnings, no errors"
    elif [ $error_count -lt 5 ] && [ $warning_count -lt 10 ]; then
        echo -e "  ${YELLOW}⚠ FAIR${NC} - Some issues detected"
    else
        echo -e "  ${RED}✗ POOR${NC} - Multiple issues detected"
    fi
    echo -e "═══════════════════════════════════════════════════\n"
}

# Main script execution
echo -e "\n${BLUE}Starting Log File Analyzer...${NC}\n"

# Check if logfile argument is provided
if [ $# -eq 0 ]; then
    echo -e "${YELLOW}No log file specified. Using default locations...${NC}\n"
    
    # Try common log locations
    if [ -f "/var/log/syslog" ]; then
        analyze_log "/var/log/syslog"
    elif [ -f "/var/log/messages" ]; then
        analyze_log "/var/log/messages"
    else
        echo -e "${YELLOW}No system logs accessible. Creating sample log...${NC}\n"
        create_sample_log
        analyze_log "sample.log"
    fi
else
    # Use provided log file
    analyze_log "$1"
fi

echo -e "${GREEN}Analysis complete!${NC}\n"
