#!/bin/bash
#
# Day 15: Service Checker & Auto-Restart
# Author: Ademola Adenigba (CloudDemigod)
# Date: November 19, 2025
#
# Real Production Script!
# Monitors critical services (nginx/apache/mysql/docker) and auto-restarts if down
# Logs all actions and sends alerts
# Can be run via cron every 5 minutes

# Color codes
RED='\033[0;31m'
YELLOW='\033[1;33m'
GREEN='\033[0;32m'
BLUE='\033[0;34m'
MAGENTA='\033[0;35m'
CYAN='\033[0;36m'
BOLD='\033[1m'
NC='\033[0m'

# Configuration
LOG_DIR="/var/log/service_monitor"
LOG_FILE="$LOG_DIR/service_monitor.log"
ALERT_LOG="$LOG_DIR/alerts.log"
STATUS_FILE="$LOG_DIR/service_status.txt"

# Services to monitor (add or remove as needed)
SERVICES=(
    "nginx"
    "apache2"
    "mysql"
    "docker"
    "ssh"
    "cron"
)

# Email configuration (optional - for production)
ENABLE_EMAIL_ALERTS=false
ALERT_EMAIL="admin@example.com"

# Auto-restart configuration
AUTO_RESTART=true
MAX_RESTART_ATTEMPTS=3

# Create log directory if it doesn't exist
setup_logging() {
    if [ ! -d "$LOG_DIR" ]; then
        mkdir -p "$LOG_DIR" 2>/dev/null
        if [ $? -ne 0 ]; then
            # If can't create in /var/log, use home directory
            LOG_DIR="$HOME/.service_monitor"
            mkdir -p "$LOG_DIR"
            LOG_FILE="$LOG_DIR/service_monitor.log"
            ALERT_LOG="$LOG_DIR/alerts.log"
            STATUS_FILE="$LOG_DIR/service_status.txt"
        fi
    fi
}

# Function to get timestamp
get_timestamp() {
    date '+%Y-%m-%d %H:%M:%S'
}

# Function to log messages
log_message() {
    local level=$1
    local message=$2
    echo "[$(get_timestamp)] [$level] $message" >> "$LOG_FILE"
    
    # Also log alerts to separate file
    if [ "$level" = "ALERT" ] || [ "$level" = "CRITICAL" ]; then
        echo "[$(get_timestamp)] $message" >> "$ALERT_LOG"
    fi
}

# Function to send email alert (simulated)
send_alert() {
    local subject=$1
    local message=$2
    
    if [ "$ENABLE_EMAIL_ALERTS" = true ]; then
        # In production, use: mail -s "$subject" "$ALERT_EMAIL" <<< "$message"
        # For now, just log it
        log_message "EMAIL" "Would send: $subject - $message"
        echo -e "${YELLOW}📧 Alert email queued: $subject${NC}"
    fi
}

# Function to print header
print_header() {
    echo -e "${CYAN}╔═══════════════════════════════════════════════════════════════╗${NC}"
    echo -e "${CYAN}║           SERVICE MONITORING & AUTO-RESTART                   ║${NC}"
    echo -e "${CYAN}║              Production Service Manager                       ║${NC}"
    echo -e "${CYAN}╔═══════════════════════════════════════════════════════════════╗${NC}"
    echo -e "${BLUE}Timestamp: $(get_timestamp)${NC}"
    echo -e "${BLUE}Log File:  $LOG_FILE${NC}\n"
}

# Function to check if service exists
service_exists() {
    local service=$1
    
    # Check systemctl first (systemd)
    if command -v systemctl &> /dev/null; then
        systemctl list-unit-files | grep -q "^${service}.service" && return 0
    fi
    
    # Check service command (SysVinit)
    if command -v service &> /dev/null; then
        service --status-all 2>&1 | grep -q "$service" && return 0
    fi
    
    # Check if process is running
    pgrep -x "$service" &> /dev/null && return 0
    
    return 1
}

# Function to check service status
check_service_status() {
    local service=$1
    
    # Try systemctl first
    if command -v systemctl &> /dev/null; then
        if systemctl is-active --quiet "$service" 2>/dev/null; then
            return 0
        fi
    fi
    
    # Try service command
    if command -v service &> /dev/null; then
        if service "$service" status &> /dev/null; then
            return 0
        fi
    fi
    
    # Check if process is running
    if pgrep -x "$service" &> /dev/null; then
        return 0
    fi
    
    return 1
}

# Function to start service
start_service() {
    local service=$1
    
    # Try systemctl
    if command -v systemctl &> /dev/null; then
        systemctl start "$service" 2>/dev/null && return 0
    fi
    
    # Try service command
    if command -v service &> /dev/null; then
        service "$service" start 2>/dev/null && return 0
    fi
    
    return 1
}

# Function to get service uptime
get_service_uptime() {
    local service=$1
    
    if command -v systemctl &> /dev/null; then
        local uptime=$(systemctl show "$service" --property=ActiveEnterTimestamp --value 2>/dev/null)
        if [ ! -z "$uptime" ] && [ "$uptime" != "n/a" ]; then
            local start_time=$(date -d "$uptime" +%s 2>/dev/null)
            local current_time=$(date +%s)
            local uptime_seconds=$((current_time - start_time))
            
            local days=$((uptime_seconds / 86400))
            local hours=$(( (uptime_seconds % 86400) / 3600 ))
            local minutes=$(( (uptime_seconds % 3600) / 60 ))
            
            if [ $days -gt 0 ]; then
                echo "${days}d ${hours}h ${minutes}m"
            elif [ $hours -gt 0 ]; then
                echo "${hours}h ${minutes}m"
            else
                echo "${minutes}m"
            fi
            return 0
        fi
    fi
    
    echo "unknown"
}

# Function to get restart count from log
get_restart_count() {
    local service=$1
    local today=$(date +%Y-%m-%d)
    
    grep "$today" "$LOG_FILE" 2>/dev/null | grep -c "Restarted $service" || echo 0
}

# Function to monitor single service
monitor_service() {
    local service=$1
    local status="UNKNOWN"
    local action=""
    local color=$YELLOW
    
    # Check if service exists
    if ! service_exists "$service"; then
        status="NOT_INSTALLED"
        color=$YELLOW
        echo -e "${color}⊘ $service${NC} - Not installed/configured"
        log_message "INFO" "$service: Not installed or not configured"
        return 0
    fi
    
    # Check service status
    if check_service_status "$service"; then
        status="RUNNING"
        color=$GREEN
        local uptime=$(get_service_uptime "$service")
        local restart_count=$(get_restart_count "$service")
        
        echo -e "${color}✓ $service${NC} - Running (Uptime: $uptime)"
        
        if [ $restart_count -gt 0 ]; then
            echo -e "  ${YELLOW}⚠ Restarted $restart_count time(s) today${NC}"
        fi
        
        log_message "INFO" "$service: Running (Uptime: $uptime)"
    else
        status="DOWN"
        color=$RED
        echo -e "${color}✗ $service${NC} - Service is DOWN!"
        log_message "CRITICAL" "$service: Service is DOWN!"
        
        # Auto-restart if enabled
        if [ "$AUTO_RESTART" = true ]; then
            attempt_restart "$service"
        else
            echo -e "  ${YELLOW}⚠ Auto-restart is disabled${NC}"
            send_alert "Service Down: $service" "$service is down and auto-restart is disabled"
        fi
    fi
    
    # Save status to file for historical tracking
    echo "$(get_timestamp)|$service|$status" >> "$STATUS_FILE"
}

# Function to attempt service restart
attempt_restart() {
    local service=$1
    local restart_count=$(get_restart_count "$service")
    
    if [ $restart_count -ge $MAX_RESTART_ATTEMPTS ]; then
        echo -e "  ${RED}✗ Max restart attempts ($MAX_RESTART_ATTEMPTS) reached today${NC}"
        log_message "CRITICAL" "$service: Max restart attempts reached. Manual intervention required!"
        send_alert "CRITICAL: $service restart failed" "$service has failed $MAX_RESTART_ATTEMPTS times today. Manual intervention required!"
        return 1
    fi
    
    echo -e "  ${YELLOW}⟳ Attempting to restart $service...${NC}"
    log_message "ALERT" "$service: Attempting restart (attempt $((restart_count + 1))/$MAX_RESTART_ATTEMPTS)"
    
    if start_service "$service"; then
        sleep 3  # Wait for service to stabilize
        
        if check_service_status "$service"; then
            echo -e "  ${GREEN}✓ Successfully restarted $service${NC}"
            log_message "INFO" "$service: Successfully restarted"
            send_alert "Service Recovered: $service" "$service was down and has been successfully restarted"
            return 0
        else
            echo -e "  ${RED}✗ Service started but not responding${NC}"
            log_message "CRITICAL" "$service: Restart failed - service not responding"
            send_alert "CRITICAL: $service restart failed" "$service restart failed - service not responding"
            return 1
        fi
    else
        echo -e "  ${RED}✗ Failed to restart $service${NC}"
        log_message "CRITICAL" "$service: Restart command failed"
        send_alert "CRITICAL: $service restart failed" "$service restart command failed"
        return 1
    fi
}

# Function to monitor all services
monitor_all_services() {
    echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo -e "${MAGENTA}📊 Service Status Overview${NC}"
    echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}\n"
    
    local total_services=${#SERVICES[@]}
    local running_services=0
    local down_services=0
    local not_installed=0
    
    for service in "${SERVICES[@]}"; do
        if ! service_exists "$service"; then
            ((not_installed++))
        elif check_service_status "$service"; then
            ((running_services++))
        else
            ((down_services++))
        fi
        
        monitor_service "$service"
        echo ""
    done
    
    # Summary
    echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo -e "${MAGENTA}📈 Summary${NC}"
    echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}\n"
    
    echo -e "${CYAN}Total Services Monitored:${NC}  $total_services"
    echo -e "${GREEN}Running:${NC}                   $running_services"
    echo -e "${RED}Down:${NC}                      $down_services"
    echo -e "${YELLOW}Not Installed:${NC}             $not_installed"
    
    # Health percentage
    local monitored=$((running_services + down_services))
    local health_percent=0
    if [ $monitored -gt 0 ]; then
        health_percent=$((running_services * 100 / monitored))
    fi
    
    echo -e "\n${CYAN}System Health:${NC}             "
    
    if [ $health_percent -eq 100 ]; then
        echo -e "${GREEN}${BOLD}$health_percent% - EXCELLENT${NC}"
    elif [ $health_percent -ge 80 ]; then
        echo -e "${YELLOW}${BOLD}$health_percent% - GOOD${NC}"
    elif [ $health_percent -ge 60 ]; then
        echo -e "${YELLOW}${BOLD}$health_percent% - FAIR${NC}"
    else
        echo -e "${RED}${BOLD}$health_percent% - CRITICAL${NC}"
    fi
    
    echo ""
}

# Function to show recent alerts
show_recent_alerts() {
    echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo -e "${MAGENTA}🚨 Recent Alerts (Last 24 Hours)${NC}"
    echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}\n"
    
    if [ -f "$ALERT_LOG" ]; then
        local yesterday=$(date -d "yesterday" +%Y-%m-%d 2>/dev/null || date -v-1d +%Y-%m-%d 2>/dev/null)
        local today=$(date +%Y-%m-%d)
        
        local alert_count=$(grep -E "$yesterday|$today" "$ALERT_LOG" 2>/dev/null | wc -l)
        
        if [ $alert_count -gt 0 ]; then
            grep -E "$yesterday|$today" "$ALERT_LOG" 2>/dev/null | tail -10 | while read line; do
                echo -e "${YELLOW}⚠${NC} $line"
            done
            
            if [ $alert_count -gt 10 ]; then
                echo -e "\n${CYAN}... and $((alert_count - 10)) more alerts${NC}"
            fi
        else
            echo -e "${GREEN}No alerts in the last 24 hours${NC}"
        fi
    else
        echo -e "${GREEN}No alerts recorded yet${NC}"
    fi
    
    echo ""
}

# Function to setup cron job
setup_cron() {
    echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo -e "${MAGENTA}⏰ Setup Cron Job for Automatic Monitoring${NC}"
    echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}\n"
    
    local script_path=$(readlink -f "$0")
    
    echo -e "${CYAN}This will run the service checker every 5 minutes${NC}"
    echo -e "${YELLOW}Cron entry:${NC}"
    echo -e "${GREEN}*/5 * * * * $script_path --auto >> $LOG_DIR/cron.log 2>&1${NC}\n"
    
    read -p "Add this cron job? (yes/no): " confirm
    
    if [ "$confirm" = "yes" ]; then
        # Add to crontab
        (crontab -l 2>/dev/null; echo "*/5 * * * * $script_path --auto >> $LOG_DIR/cron.log 2>&1") | crontab -
        echo -e "\n${GREEN}✓ Cron job added successfully!${NC}"
        echo -e "${CYAN}The service checker will now run every 5 minutes${NC}\n"
        log_message "INFO" "Cron job configured for automatic monitoring"
    else
        echo -e "\n${YELLOW}Cron setup cancelled${NC}\n"
    fi
}

# Function to show usage
print_usage() {
    echo -e "${CYAN}Usage:${NC}"
    echo -e "  $0 [OPTIONS]"
    echo -e ""
    echo -e "${CYAN}Options:${NC}"
    echo -e "  ${GREEN}--auto${NC}         Run in automatic mode (for cron, no colors)"
    echo -e "  ${GREEN}--setup-cron${NC}   Setup automatic monitoring via cron"
    echo -e "  ${GREEN}--alerts${NC}       Show recent alerts"
    echo -e "  ${GREEN}--no-restart${NC}   Check only, don't auto-restart services"
    echo -e "  ${GREEN}--help${NC}         Show this help message"
    echo -e ""
    echo -e "${CYAN}Examples:${NC}"
    echo -e "  ${YELLOW}sudo $0${NC}              # Check all services now"
    echo -e "  ${YELLOW}sudo $0 --alerts${NC}     # View recent alerts"
    echo -e "  ${YELLOW}sudo $0 --setup-cron${NC} # Setup automatic monitoring"
    echo ""
}

# Main execution
main() {
    setup_logging
    
    # Check if running as root
    if [ "$EUID" -ne 0 ] && [ "$1" != "--help" ]; then
        echo -e "${YELLOW}⚠ Warning: Running without root privileges${NC}"
        echo -e "${YELLOW}Some services may not be accessible${NC}\n"
    fi
    
    # Parse arguments
    case "$1" in
        --auto)
            # Automated mode (for cron, no colors, minimal output)
            log_message "INFO" "=== Automated check started ==="
            monitor_all_services > /dev/null 2>&1
            log_message "INFO" "=== Automated check completed ==="
            ;;
        --setup-cron)
            print_header
            setup_cron
            ;;
        --alerts)
            print_header
            show_recent_alerts
            ;;
        --no-restart)
            AUTO_RESTART=false
            print_header
            log_message "INFO" "=== Manual check started (no auto-restart) ==="
            monitor_all_services
            show_recent_alerts
            log_message "INFO" "=== Manual check completed ==="
            ;;
        --help|-h)
            print_header
            print_usage
            ;;
        *)
            print_header
            log_message "INFO" "=== Service check started ==="
            monitor_all_services
            show_recent_alerts
            log_message "INFO" "=== Service check completed ==="
            
            echo -e "${CYAN}💡 Tip: Run 'sudo $0 --setup-cron' to enable automatic monitoring${NC}\n"
            ;;
    esac
}

# Run the script
main "$@"
