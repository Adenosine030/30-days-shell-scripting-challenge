#!/bin/bash
#
# Day 10: System Health Checker
# Author: Ademola Adenigba (CloudDemigod)
# Date: November 15, 2025
#
# Real DevOps Production Script!
# Monitors CPU, Memory, and Disk usage with threshold alerts
# Logs results for historical tracking

# Color codes for output
RED='\033[0;31m'
YELLOW='\033[1;33m'
GREEN='\033[0;32m'
BLUE='\033[0;34m'
MAGENTA='\033[0;35m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

# Configuration - Thresholds
CPU_THRESHOLD=80
MEMORY_THRESHOLD=80
DISK_THRESHOLD=90

# Log file configuration
LOG_DIR="$HOME/health_checks"
LOG_FILE="$LOG_DIR/health_check.log"
ALERT_LOG="$LOG_DIR/alerts.log"

# Create log directory if it doesn't exist
mkdir -p "$LOG_DIR"

# Function to get current timestamp
get_timestamp() {
    date '+%Y-%m-%d %H:%M:%S'
}

# Function to log messages
log_message() {
    local level=$1
    local message=$2
    echo "[$(get_timestamp)] [$level] $message" >> "$LOG_FILE"
}

# Function to log alerts
log_alert() {
    local message=$1
    echo "[$(get_timestamp)] ALERT: $message" >> "$ALERT_LOG"
}

# Function to print header
print_header() {
    clear
    echo -e "${CYAN}╔═══════════════════════════════════════════════════════════════╗${NC}"
    echo -e "${CYAN}║           SYSTEM HEALTH MONITORING DASHBOARD                  ║${NC}"
    echo -e "${CYAN}║                   $(get_timestamp)                     ║${NC}"
    echo -e "${CYAN}╔═══════════════════════════════════════════════════════════════╗${NC}"
    echo ""
}

# Function to draw progress bar
draw_bar() {
    local percentage=$1
    local width=40
    local filled=$((percentage * width / 100))
    local empty=$((width - filled))
    
    # Color based on percentage
    local color=$GREEN
    if [ $percentage -ge 90 ]; then
        color=$RED
    elif [ $percentage -ge 70 ]; then
        color=$YELLOW
    fi
    
    echo -ne "${color}["
    printf '%*s' $filled | tr ' ' '█'
    printf '%*s' $empty | tr ' ' '░'
    echo -ne "]${NC} ${color}${percentage}%${NC}"
}

# Function to check CPU usage
check_cpu() {
    echo -e "\n${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo -e "${MAGENTA}🖥️  CPU USAGE${NC}"
    echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    
    # Get CPU usage (average across all cores)
    # Using top command for cross-platform compatibility
    local cpu_usage=$(top -bn1 | grep "Cpu(s)" | sed "s/.*, *\([0-9.]*\)%* id.*/\1/" | awk '{print 100 - $1}')
    
    # If top doesn't work, try alternative method
    if [ -z "$cpu_usage" ]; then
        cpu_usage=$(grep 'cpu ' /proc/stat | awk '{usage=($2+$4)*100/($2+$4+$5)} END {print usage}')
    fi
    
    # Round to integer
    cpu_usage=$(printf "%.0f" "$cpu_usage" 2>/dev/null || echo "0")
    
    echo -ne "  Current CPU Usage: "
    draw_bar $cpu_usage
    echo ""
    
    # Check against threshold
    if [ $cpu_usage -ge $CPU_THRESHOLD ]; then
        echo -e "  ${RED}⚠️  WARNING: CPU usage is above threshold (${CPU_THRESHOLD}%)!${NC}"
        log_message "WARNING" "CPU usage at ${cpu_usage}% (threshold: ${CPU_THRESHOLD}%)"
        log_alert "HIGH CPU USAGE: ${cpu_usage}%"
        
        # Show top CPU-consuming processes
        echo -e "\n  ${YELLOW}Top 3 CPU-consuming processes:${NC}"
        ps aux --sort=-%cpu | head -4 | tail -3 | awk '{printf "    %s: %s%%\n", $11, $3}'
    else
        echo -e "  ${GREEN}✓ CPU usage is normal${NC}"
        log_message "INFO" "CPU usage at ${cpu_usage}% - Normal"
    fi
}

# Function to check Memory usage
check_memory() {
    echo -e "\n${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo -e "${MAGENTA}💾 MEMORY USAGE${NC}"
    echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    
    # Get memory usage
    local mem_info=$(free | grep Mem)
    local total_mem=$(echo $mem_info | awk '{print $2}')
    local used_mem=$(echo $mem_info | awk '{print $3}')
    local mem_usage=$((used_mem * 100 / total_mem))
    
    # Convert to human-readable format
    local total_gb=$(echo "scale=2; $total_mem / 1024 / 1024" | bc)
    local used_gb=$(echo "scale=2; $used_mem / 1024 / 1024" | bc)
    local free_gb=$(echo "scale=2; ($total_mem - $used_mem) / 1024 / 1024" | bc)
    
    echo -ne "  Current Memory Usage: "
    draw_bar $mem_usage
    echo ""
    echo -e "  ${CYAN}Total: ${total_gb}GB | Used: ${used_gb}GB | Free: ${free_gb}GB${NC}"
    
    # Check against threshold
    if [ $mem_usage -ge $MEMORY_THRESHOLD ]; then
        echo -e "  ${RED}⚠️  WARNING: Memory usage is above threshold (${MEMORY_THRESHOLD}%)!${NC}"
        log_message "WARNING" "Memory usage at ${mem_usage}% (threshold: ${MEMORY_THRESHOLD}%)"
        log_alert "HIGH MEMORY USAGE: ${mem_usage}%"
        
        # Show top memory-consuming processes
        echo -e "\n  ${YELLOW}Top 3 Memory-consuming processes:${NC}"
        ps aux --sort=-%mem | head -4 | tail -3 | awk '{printf "    %s: %s%%\n", $11, $4}'
    else
        echo -e "  ${GREEN}✓ Memory usage is normal${NC}"
        log_message "INFO" "Memory usage at ${mem_usage}% - Normal"
    fi
}

# Function to check Disk usage
check_disk() {
    echo -e "\n${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo -e "${MAGENTA}💿 DISK USAGE${NC}"
    echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    
    local alert_triggered=false
    
    # Check all mounted filesystems
    df -h | grep -vE '^Filesystem|tmpfs|cdrom|loop' | while read line; do
        local filesystem=$(echo $line | awk '{print $1}')
        local mount_point=$(echo $line | awk '{print $6}')
        local usage=$(echo $line | awk '{print $5}' | sed 's/%//')
        local used=$(echo $line | awk '{print $3}')
        local available=$(echo $line | awk '{print $4}')
        
        echo -e "\n  ${CYAN}Mount Point: ${mount_point}${NC}"
        echo -ne "  Disk Usage: "
        draw_bar $usage
        echo ""
        echo -e "  ${CYAN}Used: ${used} | Available: ${available}${NC}"
        
        # Check against threshold
        if [ $usage -ge $DISK_THRESHOLD ]; then
            echo -e "  ${RED}⚠️  CRITICAL: Disk usage is above threshold (${DISK_THRESHOLD}%)!${NC}"
            log_message "CRITICAL" "Disk usage at ${usage}% on ${mount_point} (threshold: ${DISK_THRESHOLD}%)"
            log_alert "CRITICAL DISK USAGE: ${usage}% on ${mount_point}"
            alert_triggered=true
            
            # Show largest directories
            echo -e "  ${YELLOW}Top 3 largest directories in ${mount_point}:${NC}"
            du -sh ${mount_point}/* 2>/dev/null | sort -rh | head -3 | awk '{printf "    %s - %s\n", $2, $1}'
        else
            echo -e "  ${GREEN}✓ Disk usage is normal${NC}"
            log_message "INFO" "Disk usage at ${usage}% on ${mount_point} - Normal"
        fi
    done
}

# Function to generate summary report
generate_summary() {
    echo -e "\n${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo -e "${MAGENTA}📊 HEALTH CHECK SUMMARY${NC}"
    echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    
    # Count recent alerts
    local alert_count=0
    if [ -f "$ALERT_LOG" ]; then
        alert_count=$(grep "$(date +%Y-%m-%d)" "$ALERT_LOG" | wc -l)
    fi
    
    echo -e "  ${CYAN}Thresholds Configured:${NC}"
    echo -e "    • CPU Threshold:    ${YELLOW}${CPU_THRESHOLD}%${NC}"
    echo -e "    • Memory Threshold: ${YELLOW}${MEMORY_THRESHOLD}%${NC}"
    echo -e "    • Disk Threshold:   ${YELLOW}${DISK_THRESHOLD}%${NC}"
    echo ""
    echo -e "  ${CYAN}Today's Alert Count: ${NC}${RED}${alert_count}${NC}"
    echo ""
    echo -e "  ${CYAN}Log Files:${NC}"
    echo -e "    • Health Log: ${LOG_FILE}"
    echo -e "    • Alert Log:  ${ALERT_LOG}"
    echo ""
}

# Function to show system information
show_system_info() {
    echo -e "\n${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo -e "${MAGENTA}ℹ️  SYSTEM INFORMATION${NC}"
    echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    
    echo -e "  ${CYAN}Hostname:${NC}     $(hostname)"
    echo -e "  ${CYAN}OS:${NC}           $(uname -s) $(uname -r)"
    echo -e "  ${CYAN}Uptime:${NC}       $(uptime -p 2>/dev/null || uptime | awk '{print $3" "$4}')"
    echo -e "  ${CYAN}CPU Cores:${NC}    $(nproc)"
    echo -e "  ${CYAN}Load Average:${NC} $(uptime | awk -F'load average:' '{print $2}')"
}

# Main execution
main() {
    print_header
    
    log_message "INFO" "=== Health Check Started ==="
    
    show_system_info
    check_cpu
    check_memory
    check_disk
    generate_summary
    
    log_message "INFO" "=== Health Check Completed ==="
    
    echo -e "\n${GREEN}✅ Health check completed successfully!${NC}"
    echo -e "${CYAN}Check logs at: ${LOG_FILE}${NC}\n"
}

# Run the script
main
