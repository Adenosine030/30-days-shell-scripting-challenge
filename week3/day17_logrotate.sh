#!/bin/bash
#
# Day 17: Log Rotation Script
# Author: Ademola Adenigba (CloudDemigod)
# Date: November 20, 2025
#
# Manages log files: compresses old logs, deletes ancient logs
# Critical for production servers!
# Usage: ./day17_logrotate.sh

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
LOG_DIR="${1:-/var/log/myapp}"  # Default log directory (can be passed as argument)
COMPRESS_DAYS=7                  # Compress logs older than 7 days
DELETE_DAYS=30                   # Delete logs older than 30 days
REPORT_FILE="/tmp/log_rotation_report_$(date +%Y%m%d_%H%M%S).txt"

# Counters
COMPRESSED_COUNT=0
DELETED_COUNT=0
TOTAL_SPACE_FREED=0

# Function to print header
print_header() {
    clear
    echo -e "${CYAN}╔═══════════════════════════════════════════════════════════════╗${NC}"
    echo -e "${CYAN}║              LOG ROTATION & MANAGEMENT                        ║${NC}"
    echo -e "${CYAN}║           Keep Your Servers Clean & Efficient                 ║${NC}"
    echo -e "${CYAN}╔═══════════════════════════════════════════════════════════════╗${NC}"
    echo -e "${BLUE}Target Directory: ${CYAN}${LOG_DIR}${NC}"
    echo -e "${BLUE}Timestamp:        ${CYAN}$(date '+%Y-%m-%d %H:%M:%S')${NC}\n"
}

# Function to validate directory
validate_directory() {
    if [ ! -d "$LOG_DIR" ]; then
        echo -e "${YELLOW}⚠️  Directory '$LOG_DIR' does not exist.${NC}"
        read -p "Create it? (yes/no): " create
        
        if [ "$create" = "yes" ]; then
            mkdir -p "$LOG_DIR"
            echo -e "${GREEN}✓ Directory created${NC}\n"
            
            # Create sample log files for testing
            create_sample_logs
        else
            echo -e "${RED}Cannot proceed without log directory. Exiting.${NC}"
            exit 1
        fi
    fi
    
    if [ ! -r "$LOG_DIR" ]; then
        echo -e "${RED}Error: No read permission for '$LOG_DIR'${NC}"
        exit 1
    fi
}

# Function to create sample logs for testing
create_sample_logs() {
    echo -e "${CYAN}Creating sample log files for testing...${NC}\n"
    
    # Recent logs (don't compress)
    for i in {1..3}; do
        touch -d "$i days ago" "$LOG_DIR/app_$(date -d "$i days ago" +%Y%m%d).log"
        echo "Sample log entry from $i days ago" > "$LOG_DIR/app_$(date -d "$i days ago" +%Y%m%d).log"
    done
    
    # Old logs (should be compressed)
    for i in {8..15}; do
        touch -d "$i days ago" "$LOG_DIR/app_$(date -d "$i days ago" +%Y%m%d).log"
        echo "Sample log entry from $i days ago - This should be compressed" > "$LOG_DIR/app_$(date -d "$i days ago" +%Y%m%d).log"
    done
    
    # Ancient logs (should be deleted)
    for i in {31..40}; do
        touch -d "$i days ago" "$LOG_DIR/app_$(date -d "$i days ago" +%Y%m%d).log"
        echo "Sample log entry from $i days ago - This should be deleted" > "$LOG_DIR/app_$(date -d "$i days ago" +%Y%m%d).log"
    done
    
    echo -e "${GREEN}✓ Sample logs created${NC}\n"
}

# Function to get file age in days
get_file_age() {
    local file=$1
    local current_time=$(date +%s)
    local file_time=$(stat -c %Y "$file" 2>/dev/null || stat -f %m "$file" 2>/dev/null)
    local age_seconds=$((current_time - file_time))
    local age_days=$((age_seconds / 86400))
    echo $age_days
}

# Function to get file size
get_file_size() {
    local file=$1
    stat -c %s "$file" 2>/dev/null || stat -f %z "$file" 2>/dev/null
}

# Function to convert bytes to human readable
bytes_to_human() {
    local bytes=$1
    local sizes=("B" "KB" "MB" "GB")
    local size_index=0
    local size=$bytes
    
    while (( $(echo "$size >= 1024" | bc -l) )) && [ $size_index -lt 3 ]; do
        size=$(echo "scale=2; $size / 1024" | bc)
        ((size_index++))
    done
    
    printf "%.2f %s" "$size" "${sizes[$size_index]}"
}

# Function to scan logs
scan_logs() {
    echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo -e "${MAGENTA}📊 Scanning Log Files${NC}"
    echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}\n"
    
    local total_logs=0
    local recent_logs=0
    local old_logs=0
    local ancient_logs=0
    local total_size=0
    
    # Find all .log files
    while IFS= read -r logfile; do
        if [ -f "$logfile" ]; then
            ((total_logs++))
            local age=$(get_file_age "$logfile")
            local size=$(get_file_size "$logfile")
            total_size=$((total_size + size))
            
            if [ $age -lt $COMPRESS_DAYS ]; then
                ((recent_logs++))
            elif [ $age -lt $DELETE_DAYS ]; then
                ((old_logs++))
            else
                ((ancient_logs++))
            fi
        fi
    done < <(find "$LOG_DIR" -name "*.log" -type f)
    
    echo -e "${CYAN}Total Log Files:${NC}        ${total_logs}"
    echo -e "${GREEN}Recent (< $COMPRESS_DAYS days):${NC}    ${recent_logs} ${YELLOW}(Keep as-is)${NC}"
    echo -e "${YELLOW}Old ($COMPRESS_DAYS-$DELETE_DAYS days):${NC}     ${old_logs} ${YELLOW}(Will compress)${NC}"
    echo -e "${RED}Ancient (> $DELETE_DAYS days):${NC}  ${ancient_logs} ${YELLOW}(Will delete)${NC}"
    echo -e "${CYAN}Total Size:${NC}             $(bytes_to_human $total_size)\n"
}

# Function to compress old logs
compress_logs() {
    echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo -e "${MAGENTA}📦 Compressing Old Logs (${COMPRESS_DAYS}-${DELETE_DAYS} days old)${NC}"
    echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}\n"
    
    local current_date=$(date +%s)
    local compress_threshold=$((current_date - (COMPRESS_DAYS * 86400)))
    local delete_threshold=$((current_date - (DELETE_DAYS * 86400)))
    
    # Find logs to compress (between 7-30 days old)
    while IFS= read -r logfile; do
        if [ -f "$logfile" ] && [[ ! "$logfile" =~ \.gz$ ]]; then
            local file_time=$(stat -c %Y "$logfile" 2>/dev/null || stat -f %m "$logfile" 2>/dev/null)
            
            # Check if file is between compress and delete thresholds
            if [ $file_time -lt $compress_threshold ] && [ $file_time -gt $delete_threshold ]; then
                local original_size=$(get_file_size "$logfile")
                local age=$(get_file_age "$logfile")
                
                echo -e "${YELLOW}⟳${NC} Compressing: $(basename "$logfile") (${age} days old, $(bytes_to_human $original_size))"
                
                # Compress the file
                if gzip -f "$logfile" 2>/dev/null; then
                    local compressed_file="${logfile}.gz"
                    local compressed_size=$(get_file_size "$compressed_file")
                    local saved=$((original_size - compressed_size))
                    
                    echo -e "  ${GREEN}✓${NC} Compressed to $(bytes_to_human $compressed_size) - Saved $(bytes_to_human $saved)\n"
                    
                    ((COMPRESSED_COUNT++))
                    TOTAL_SPACE_FREED=$((TOTAL_SPACE_FREED + saved))
                else
                    echo -e "  ${RED}✗${NC} Failed to compress\n"
                fi
            fi
        fi
    done < <(find "$LOG_DIR" -name "*.log" -type f)
    
    if [ $COMPRESSED_COUNT -eq 0 ]; then
        echo -e "${GREEN}No logs need compression at this time${NC}\n"
    else
        echo -e "${GREEN}✓ Compressed ${COMPRESSED_COUNT} log file(s)${NC}\n"
    fi
}

# Function to delete ancient logs
delete_old_logs() {
    echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo -e "${MAGENTA}🗑️  Deleting Ancient Logs (> ${DELETE_DAYS} days old)${NC}"
    echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}\n"
    
    local current_date=$(date +%s)
    local delete_threshold=$((current_date - (DELETE_DAYS * 86400)))
    
    # Find logs to delete (older than 30 days)
    while IFS= read -r logfile; do
        if [ -f "$logfile" ]; then
            local file_time=$(stat -c %Y "$logfile" 2>/dev/null || stat -f %m "$logfile" 2>/dev/null)
            
            if [ $file_time -lt $delete_threshold ]; then
                local file_size=$(get_file_size "$logfile")
                local age=$(get_file_age "$logfile")
                
                echo -e "${RED}✗${NC} Deleting: $(basename "$logfile") (${age} days old, $(bytes_to_human $file_size))"
                
                if rm "$logfile" 2>/dev/null; then
                    echo -e "  ${GREEN}✓${NC} Deleted successfully\n"
                    
                    ((DELETED_COUNT++))
                    TOTAL_SPACE_FREED=$((TOTAL_SPACE_FREED + file_size))
                else
                    echo -e "  ${RED}✗${NC} Failed to delete\n"
                fi
            fi
        fi
    done < <(find "$LOG_DIR" -name "*.log*" -type f)
    
    if [ $DELETED_COUNT -eq 0 ]; then
        echo -e "${GREEN}No ancient logs to delete at this time${NC}\n"
    else
        echo -e "${GREEN}✓ Deleted ${DELETED_COUNT} ancient log file(s)${NC}\n"
    fi
}

# Function to generate summary report
generate_report() {
    echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo -e "${MAGENTA}📋 Summary Report${NC}"
    echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}\n"
    
    echo -e "${CYAN}Directory:${NC}           $LOG_DIR"
    echo -e "${CYAN}Execution Time:${NC}      $(date '+%Y-%m-%d %H:%M:%S')"
    echo -e "${CYAN}Logs Compressed:${NC}     ${GREEN}${COMPRESSED_COUNT}${NC}"
    echo -e "${CYAN}Logs Deleted:${NC}        ${RED}${DELETED_COUNT}${NC}"
    echo -e "${CYAN}Total Space Freed:${NC}   ${YELLOW}$(bytes_to_human $TOTAL_SPACE_FREED)${NC}"
    
    # Count remaining logs
    local remaining=$(find "$LOG_DIR" -name "*.log*" -type f | wc -l)
    echo -e "${CYAN}Remaining Logs:${NC}      ${remaining}"
    
    # Calculate total remaining size
    local remaining_size=0
    while IFS= read -r file; do
        local size=$(get_file_size "$file")
        remaining_size=$((remaining_size + size))
    done < <(find "$LOG_DIR" -name "*.log*" -type f)
    
    echo -e "${CYAN}Remaining Size:${NC}      $(bytes_to_human $remaining_size)\n"
    
    # Save report to file
    {
        echo "Log Rotation Report"
        echo "Generated: $(date '+%Y-%m-%d %H:%M:%S')"
        echo "================================"
        echo ""
        echo "Directory: $LOG_DIR"
        echo "Logs Compressed: $COMPRESSED_COUNT"
        echo "Logs Deleted: $DELETED_COUNT"
        echo "Total Space Freed: $(bytes_to_human $TOTAL_SPACE_FREED)"
        echo "Remaining Logs: $remaining"
        echo "Remaining Size: $(bytes_to_human $remaining_size)"
        echo ""
        echo "Configuration:"
        echo "  - Compress logs older than: $COMPRESS_DAYS days"
        echo "  - Delete logs older than: $DELETE_DAYS days"
    } > "$REPORT_FILE"
    
    echo -e "${GREEN}✓ Report saved to: ${CYAN}$REPORT_FILE${NC}\n"
}

# Function to show disk space before/after
show_disk_space() {
    echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo -e "${MAGENTA}💾 Disk Space Impact${NC}"
    echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}\n"
    
    df -h "$LOG_DIR" | tail -1 | awk '{
        printf "Filesystem:  %s\n", $1
        printf "Total:       %s\n", $2
        printf "Used:        %s\n", $3
        printf "Available:   %s\n", $4
        printf "Usage:       %s\n", $5
    }'
    echo ""
}

# Main execution
main() {
    print_header
    validate_directory
    
    echo -e "${CYAN}Starting log rotation process...${NC}\n"
    
    # Show disk space before
    echo -e "${BOLD}Before Rotation:${NC}"
    show_disk_space
    
    # Scan logs
    scan_logs
    
    # Ask for confirmation
    echo -e "${YELLOW}Proceed with log rotation?${NC}"
    echo -e "  - Compress logs ${COMPRESS_DAYS}-${DELETE_DAYS} days old"
    echo -e "  - Delete logs older than ${DELETE_DAYS} days"
    read -p "Continue? (yes/no): " confirm
    echo ""
    
    if [ "$confirm" != "yes" ]; then
        echo -e "${YELLOW}Log rotation cancelled${NC}\n"
        exit 0
    fi
    
    # Compress old logs
    compress_logs
    
    # Delete ancient logs
    delete_old_logs
    
    # Generate report
    generate_report
    
    # Show disk space after
    echo -e "${BOLD}After Rotation:${NC}"
    show_disk_space
    
    echo -e "${GREEN}✅ Log rotation completed successfully!${NC}\n"
}

# Run the script
main
