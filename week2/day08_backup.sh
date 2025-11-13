#!/bin/bash
#
# ===============================
# Day 8: File Backup Script
# ===============================
# Author: CloudDemigod (Adenosine030)
# Date: 2025-11-13
# Purpose: Automated backup with compression and timestamping
# Usage: ./day08_backup.sh /path/to/directory
#

# Colors
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

# ===============================
# Configuration
# ===============================
BACKUP_DIR="$HOME/backups"
TIMESTAMP=$(date +%Y%m%d_%H%M%S)

# ===============================
# Functions
# ===============================

# Display usage information
usage() {
    echo -e "${YELLOW}Usage: $0 <directory_path>${NC}"
    echo ""
    echo "Example:"
    echo "  $0 ~/Documents"
    echo "  $0 /var/www/html"
    echo ""
    exit 1
}

# Display header
show_header() {
    echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo -e "${BLUE}      📦 AUTOMATED BACKUP SCRIPT${NC}"
    echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo ""
}

# Validate input
validate_input() {
    # Check if argument provided
    if [ $# -eq 0 ]; then
        echo -e "${RED}❌ Error: No directory specified!${NC}"
        echo ""
        usage
    fi

    # Check if directory exists
    if [ ! -d "$SOURCE_DIR" ]; then
        echo -e "${RED}❌ Error: Directory does not exist: $SOURCE_DIR${NC}"
        exit 1
    fi

    # Check if directory is readable
    if [ ! -r "$SOURCE_DIR" ]; then
        echo -e "${RED}❌ Error: Cannot read directory: $SOURCE_DIR${NC}"
        echo -e "${YELLOW}Hint: Check permissions or use sudo${NC}"
        exit 1
    fi
}

# Create backup directory if it doesn't exist
prepare_backup_dir() {
    if [ ! -d "$BACKUP_DIR" ]; then
        echo -e "${YELLOW}Creating backup directory: $BACKUP_DIR${NC}"
        mkdir -p "$BACKUP_DIR"
        
        if [ $? -eq 0 ]; then
            echo -e "${GREEN}✅ Backup directory created${NC}"
        else
            echo -e "${RED}❌ Failed to create backup directory${NC}"
            exit 1
        fi
        echo ""
    fi
}

# Perform backup
perform_backup() {
    local dir_name=$(basename "$SOURCE_DIR")
    local backup_name="${dir_name}_${TIMESTAMP}.tar.gz"
    local backup_path="$BACKUP_DIR/$backup_name"
    
    echo -e "${YELLOW}📂 Source: $SOURCE_DIR${NC}"
    echo -e "${YELLOW}📦 Backup: $backup_name${NC}"
    echo ""
    
    echo -e "${BLUE}🔄 Creating backup...${NC}"
    
    # Create compressed backup
    tar -czf "$backup_path" -C "$(dirname "$SOURCE_DIR")" "$(basename "$SOURCE_DIR")" 2>/dev/null
    
    # Check if backup was successful
    if [ $? -eq 0 ] && [ -f "$backup_path" ]; then
        echo -e "${GREEN}✅ Backup created successfully!${NC}"
        echo ""
        
        # Get backup size
        local size=$(du -h "$backup_path" | cut -f1)
        
        # Display results
        echo -e "${GREEN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
        echo -e "${GREEN}      📊 BACKUP SUMMARY${NC}"
        echo -e "${GREEN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
        echo -e "📁 Backup Name:     ${YELLOW}$backup_name${NC}"
        echo -e "📍 Location:        ${YELLOW}$BACKUP_DIR${NC}"
        echo -e "💾 Size:            ${YELLOW}$size${NC}"
        echo -e "⏰ Created:         ${YELLOW}$(date '+%Y-%m-%d %H:%M:%S')${NC}"
        echo -e "${GREEN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
        echo ""
        
        # List recent backups
        list_recent_backups
        
        return 0
    else
        echo -e "${RED}❌ Backup failed!${NC}"
        echo -e "${YELLOW}Check if you have write permissions to $BACKUP_DIR${NC}"
        exit 1
    fi
}

# List recent backups
list_recent_backups() {
    local backup_count=$(ls -1 "$BACKUP_DIR" 2>/dev/null | wc -l)
    
    if [ $backup_count -gt 0 ]; then
        echo -e "${BLUE}📋 Recent Backups (Last 5):${NC}"
        echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
        ls -lth "$BACKUP_DIR" | head -6 | tail -5 | awk '{printf "  %s  %-40s  %s\n", $6" "$7, $9, $5}'
        echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
        echo -e "${YELLOW}Total backups: $backup_count${NC}"
        echo ""
    fi
}

# Calculate total backup size
show_storage_info() {
    local total_size=$(du -sh "$BACKUP_DIR" 2>/dev/null | cut -f1)
    echo -e "${BLUE}💽 Total backup storage used: ${YELLOW}$total_size${NC}"
    echo ""
}

# ===============================
# Main Script
# ===============================

# Get source directory from argument
SOURCE_DIR="$1"

# Display header
show_header

# Validate input
validate_input "$@"

# Prepare backup directory
prepare_backup_dir

# Perform the backup
perform_backup

# Show storage info
show_storage_info

# Success message
echo -e "${GREEN}🎉 Backup completed successfully!${NC}"
echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo ""

exit 0
