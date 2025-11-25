#!/bin/bash
#
# Day 18: Database Backup Script
# Author: Ademola Adenigba (CloudDemigod)
# Date: November 23, 2025
#
# Safely backs up MySQL/PostgreSQL databases
# Compresses, manages retention, and sends notifications

# Color codes
RED='\033[0;31m'
YELLOW='\033[1;33m'
GREEN='\033[0;32m'
BLUE='\033[0;34m'
MAGENTA='\033[0;35m'
CYAN='\033[0;36m'
NC='\033[0m'

# Configuration
BACKUP_DIR="$HOME/db_backups"
RETENTION_DAYS=7  # Keep last 7 days of backups
DB_TYPE="mysql"   # mysql or postgresql

# MySQL Configuration
MYSQL_HOST="localhost"
MYSQL_USER="root"
MYSQL_PASSWORD=""  # Leave empty to prompt
MYSQL_DATABASE="myapp_db"

# PostgreSQL Configuration
PG_HOST="localhost"
PG_PORT="5432"
PG_USER="postgres"
PG_PASSWORD=""  # Leave empty to prompt
PG_DATABASE="myapp_db"

# Email Configuration (simulated)
ENABLE_NOTIFICATIONS=true
ADMIN_EMAIL="admin@example.com"

# Create backup directory
setup_backup_dir() {
    if [ ! -d "$BACKUP_DIR" ]; then
        mkdir -p "$BACKUP_DIR"
        echo -e "${GREEN}✓ Created backup directory: $BACKUP_DIR${NC}\n"
    fi
}

# Print header
print_header() {
    clear
    echo -e "${CYAN}╔═══════════════════════════════════════════════════════════════╗${NC}"
    echo -e "${CYAN}║              DATABASE BACKUP SCRIPT                           ║${NC}"
    echo -e "${CYAN}║         Safe • Automated • Production-Ready                   ║${NC}"
    echo -e "${CYAN}╔═══════════════════════════════════════════════════════════════╗${NC}"
    echo -e "${BLUE}Timestamp: $(date '+%Y-%m-%d %H:%M:%S')${NC}"
    echo -e "${BLUE}Backup Directory: $BACKUP_DIR${NC}"
    echo -e "${BLUE}Database Type: $DB_TYPE${NC}\n"
}

# Function to check if MySQL is installed
check_mysql() {
    if ! command -v mysqldump &> /dev/null; then
        echo -e "${RED}✗ mysqldump not found!${NC}"
        echo -e "${YELLOW}Install MySQL client:${NC}"
        echo -e "  Ubuntu/Debian: sudo apt-get install mysql-client"
        echo -e "  CentOS/RHEL: sudo yum install mysql"
        echo -e "  MacOS: brew install mysql-client"
        return 1
    fi
    return 0
}

# Function to check if PostgreSQL is installed
check_postgresql() {
    if ! command -v pg_dump &> /dev/null; then
        echo -e "${RED}✗ pg_dump not found!${NC}"
        echo -e "${YELLOW}Install PostgreSQL client:${NC}"
        echo -e "  Ubuntu/Debian: sudo apt-get install postgresql-client"
        echo -e "  CentOS/RHEL: sudo yum install postgresql"
        echo -e "  MacOS: brew install postgresql"
        return 1
    fi
    return 0
}

# Function to test database connection
test_connection() {
    echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo -e "${MAGENTA}🔌 Testing Database Connection${NC}"
    echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}\n"
    
    if [ "$DB_TYPE" = "mysql" ]; then
        if [ -z "$MYSQL_PASSWORD" ]; then
            read -sp "Enter MySQL password: " MYSQL_PASSWORD
            echo ""
        fi
        
        if mysql -h"$MYSQL_HOST" -u"$MYSQL_USER" -p"$MYSQL_PASSWORD" -e "USE $MYSQL_DATABASE" 2>/dev/null; then
            echo -e "${GREEN}✓ Successfully connected to MySQL database: $MYSQL_DATABASE${NC}\n"
            return 0
        else
            echo -e "${RED}✗ Failed to connect to MySQL database${NC}"
            echo -e "${YELLOW}Check your credentials and database name${NC}\n"
            return 1
        fi
    elif [ "$DB_TYPE" = "postgresql" ]; then
        if [ -z "$PG_PASSWORD" ]; then
            read -sp "Enter PostgreSQL password: " PG_PASSWORD
            echo ""
        fi
        
        export PGPASSWORD="$PG_PASSWORD"
        if psql -h "$PG_HOST" -p "$PG_PORT" -U "$PG_USER" -d "$PG_DATABASE" -c "SELECT 1" &>/dev/null; then
            echo -e "${GREEN}✓ Successfully connected to PostgreSQL database: $PG_DATABASE${NC}\n"
            return 0
        else
            echo -e "${RED}✗ Failed to connect to PostgreSQL database${NC}"
            echo -e "${YELLOW}Check your credentials and database name${NC}\n"
            return 1
        fi
    fi
}

# Function to backup MySQL database
backup_mysql() {
    local timestamp=$(date '+%Y%m%d_%H%M%S')
    local backup_file="$BACKUP_DIR/${MYSQL_DATABASE}_${timestamp}.sql"
    local compressed_file="${backup_file}.gz"
    
    echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo -e "${MAGENTA}💾 Backing Up MySQL Database${NC}"
    echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}\n"
    
    echo -e "${CYAN}Database:${NC} $MYSQL_DATABASE"
    echo -e "${CYAN}Host:${NC} $MYSQL_HOST"
    echo -e "${CYAN}Backup file:${NC} $(basename $compressed_file)\n"
    
    echo -e "${YELLOW}Creating database dump...${NC}"
    
    # Perform backup
    if mysqldump -h"$MYSQL_HOST" -u"$MYSQL_USER" -p"$MYSQL_PASSWORD" \
        --single-transaction \
        --routines \
        --triggers \
        --events \
        "$MYSQL_DATABASE" > "$backup_file" 2>/dev/null; then
        
        local dump_size=$(stat -c %s "$backup_file" 2>/dev/null || stat -f %z "$backup_file" 2>/dev/null)
        echo -e "${GREEN}✓ Database dump created: $(get_human_size $dump_size)${NC}\n"
        
        # Compress backup
        echo -e "${YELLOW}Compressing backup...${NC}"
        if gzip "$backup_file" 2>/dev/null; then
            local compressed_size=$(stat -c %s "$compressed_file" 2>/dev/null || stat -f %z "$compressed_file" 2>/dev/null)
            local compression_ratio=$(echo "scale=1; (1 - $compressed_size / $dump_size) * 100" | bc)
            
            echo -e "${GREEN}✓ Backup compressed: $(get_human_size $compressed_size)${NC}"
            echo -e "${CYAN}Compression ratio: ${compression_ratio}%${NC}\n"
            
            return 0
        else
            echo -e "${RED}✗ Failed to compress backup${NC}\n"
            return 1
        fi
    else
        echo -e "${RED}✗ Failed to create database dump${NC}\n"
        return 1
    fi
}

# Function to backup PostgreSQL database
backup_postgresql() {
    local timestamp=$(date '+%Y%m%d_%H%M%S')
    local backup_file="$BACKUP_DIR/${PG_DATABASE}_${timestamp}.sql"
    local compressed_file="${backup_file}.gz"
    
    echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo -e "${MAGENTA}💾 Backing Up PostgreSQL Database${NC}"
    echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}\n"
    
    echo -e "${CYAN}Database:${NC} $PG_DATABASE"
    echo -e "${CYAN}Host:${NC} $PG_HOST"
    echo -e "${CYAN}Backup file:${NC} $(basename $compressed_file)\n"
    
    echo -e "${YELLOW}Creating database dump...${NC}"
    
    export PGPASSWORD="$PG_PASSWORD"
    
    # Perform backup
    if pg_dump -h "$PG_HOST" -p "$PG_PORT" -U "$PG_USER" \
        -F p \
        -b \
        -v \
        "$PG_DATABASE" > "$backup_file" 2>/dev/null; then
        
        local dump_size=$(stat -c %s "$backup_file" 2>/dev/null || stat -f %z "$backup_file" 2>/dev/null)
        echo -e "${GREEN}✓ Database dump created: $(get_human_size $dump_size)${NC}\n"
        
        # Compress backup
        echo -e "${YELLOW}Compressing backup...${NC}"
        if gzip "$backup_file" 2>/dev/null; then
            local compressed_size=$(stat -c %s "$compressed_file" 2>/dev/null || stat -f %z "$compressed_file" 2>/dev/null)
            local compression_ratio=$(echo "scale=1; (1 - $compressed_size / $dump_size) * 100" | bc)
            
            echo -e "${GREEN}✓ Backup compressed: $(get_human_size $compressed_size)${NC}"
            echo -e "${CYAN}Compression ratio: ${compression_ratio}%${NC}\n"
            
            return 0
        else
            echo -e "${RED}✗ Failed to compress backup${NC}\n"
            return 1
        fi
    else
        echo -e "${RED}✗ Failed to create database dump${NC}\n"
        return 1
    fi
}

# Function to manage retention
manage_retention() {
    echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo -e "${MAGENTA}🗑️  Managing Backup Retention${NC}"
    echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}\n"
    
    echo -e "${CYAN}Retention policy: Keep last $RETENTION_DAYS days${NC}\n"
    
    local deleted_count=0
    local space_freed=0
    
    # Find and delete old backups
    while IFS= read -r backup; do
        if [ -f "$backup" ]; then
            local age=$(get_file_age_days "$backup")
            local size=$(stat -c %s "$backup" 2>/dev/null || stat -f %z "$backup" 2>/dev/null)
            
            echo -e "${YELLOW}Deleting old backup:${NC} $(basename "$backup") (Age: $age days)"
            
            if rm -f "$backup" 2>/dev/null; then
                space_freed=$((space_freed + size))
                echo -e "${GREEN}✓ Deleted${NC}\n"
                ((deleted_count++))
            fi
        fi
    done < <(find "$BACKUP_DIR" -name "*.sql.gz" -mtime +$RETENTION_DAYS 2>/dev/null)
    
    if [ $deleted_count -eq 0 ]; then
        echo -e "${GREEN}No old backups to delete${NC}\n"
    else
        echo -e "${GREEN}✓ Deleted $deleted_count old backup(s)${NC}"
        echo -e "${CYAN}Space freed: $(get_human_size $space_freed)${NC}\n"
    fi
}

# Function to list existing backups
list_backups() {
    echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo -e "${MAGENTA}📋 Existing Backups${NC}"
    echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}\n"
    
    local backup_count=$(find "$BACKUP_DIR" -name "*.sql.gz" 2>/dev/null | wc -l)
    
    if [ $backup_count -eq 0 ]; then
        echo -e "${YELLOW}No backups found${NC}\n"
    else
        echo -e "${CYAN}Total backups: $backup_count${NC}\n"
        
        find "$BACKUP_DIR" -name "*.sql.gz" 2>/dev/null | sort -r | head -10 | while read backup; do
            local size=$(stat -c %s "$backup" 2>/dev/null || stat -f %z "$backup" 2>/dev/null)
            local age=$(get_file_age_days "$backup")
            local date=$(stat -c %y "$backup" 2>/dev/null | cut -d' ' -f1 || stat -f %Sm -t "%Y-%m-%d" "$backup" 2>/dev/null)
            
            echo -e "  ${GREEN}•${NC} $(basename "$backup")"
            echo -e "    Size: $(get_human_size $size) | Age: $age days | Date: $date"
        done
        
        if [ $backup_count -gt 10 ]; then
            echo -e "\n  ${CYAN}... and $((backup_count - 10)) more${NC}"
        fi
        echo ""
    fi
}

# Function to get human-readable size
get_human_size() {
    local bytes=$1
    if [ $bytes -ge 1073741824 ]; then
        echo "$(echo "scale=2; $bytes / 1073741824" | bc) GB"
    elif [ $bytes -ge 1048576 ]; then
        echo "$(echo "scale=2; $bytes / 1048576" | bc) MB"
    elif [ $bytes -ge 1024 ]; then
        echo "$(echo "scale=2; $bytes / 1024" | bc) KB"
    else
        echo "$bytes B"
    fi
}

# Function to get file age in days
get_file_age_days() {
    local file=$1
    local current_time=$(date +%s)
    local file_time=$(stat -c %Y "$file" 2>/dev/null || stat -f %m "$file" 2>/dev/null)
    local age_seconds=$((current_time - file_time))
    echo $((age_seconds / 86400))
}

# Function to verify backup integrity
verify_backup() {
    local latest_backup=$(find "$BACKUP_DIR" -name "*.sql.gz" 2>/dev/null | sort -r | head -1)
    
    if [ -z "$latest_backup" ]; then
        return 1
    fi
    
    echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo -e "${MAGENTA}✅ Verifying Backup Integrity${NC}"
    echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}\n"
    
    echo -e "${CYAN}Testing backup: $(basename "$latest_backup")${NC}\n"
    
    # Test if gzip file is valid
    if gzip -t "$latest_backup" 2>/dev/null; then
        echo -e "${GREEN}✓ Backup file integrity: OK${NC}"
        echo -e "${GREEN}✓ Compression is valid${NC}"
        
        # Check if SQL content is readable
        if zcat "$latest_backup" | head -5 &>/dev/null; then
            echo -e "${GREEN}✓ SQL content is readable${NC}\n"
            return 0
        else
            echo -e "${RED}✗ SQL content may be corrupted${NC}\n"
            return 1
        fi
    else
        echo -e "${RED}✗ Backup file is corrupted!${NC}\n"
        return 1
    fi
}

# Function to send notification (simulated)
send_notification() {
    local status=$1
    local message=$2
    
    if [ "$ENABLE_NOTIFICATIONS" = true ]; then
        echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
        echo -e "${MAGENTA}📧 Notification${NC}"
        echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}\n"
        
        if [ "$status" = "success" ]; then
            echo -e "${GREEN}✓ Backup completed successfully${NC}"
        else
            echo -e "${RED}✗ Backup failed${NC}"
        fi
        
        echo -e "${CYAN}Notification would be sent to: $ADMIN_EMAIL${NC}"
        echo -e "${YELLOW}Message: $message${NC}\n"
        
        # In production, use:
        # echo "$message" | mail -s "Database Backup $status" "$ADMIN_EMAIL"
    fi
}

# Function to show usage
print_usage() {
    echo -e "${CYAN}Usage:${NC}"
    echo -e "  $0 [OPTIONS]"
    echo -e ""
    echo -e "${CYAN}Options:${NC}"
    echo -e "  ${GREEN}-t, --type${NC}     Database type (mysql or postgresql)"
    echo -e "  ${GREEN}-l, --list${NC}     List existing backups"
    echo -e "  ${GREEN}-v, --verify${NC}   Verify latest backup"
    echo -e "  ${GREEN}-h, --help${NC}     Show this help message"
    echo -e ""
    echo -e "${CYAN}Examples:${NC}"
    echo -e "  $0                    # Backup with default settings"
    echo -e "  $0 -t postgresql      # Backup PostgreSQL database"
    echo -e "  $0 -l                 # List all backups"
    echo -e "  $0 -v                 # Verify latest backup"
    echo ""
}

# Main execution
main() {
    # Parse arguments
    case "$1" in
        -l|--list)
            print_header
            setup_backup_dir
            list_backups
            exit 0
            ;;
        -v|--verify)
            print_header
            setup_backup_dir
            verify_backup
            exit $?
            ;;
        -t|--type)
            DB_TYPE="$2"
            ;;
        -h|--help)
            print_header
            print_usage
            exit 0
            ;;
    esac
    
    print_header
    setup_backup_dir
    
    # Check if database tools are installed
    if [ "$DB_TYPE" = "mysql" ]; then
        check_mysql || exit 1
    elif [ "$DB_TYPE" = "postgresql" ]; then
        check_postgresql || exit 1
    else
        echo -e "${RED}Invalid database type: $DB_TYPE${NC}"
        echo -e "${YELLOW}Supported types: mysql, postgresql${NC}\n"
        exit 1
    fi
    
    # Test connection
    if ! test_connection; then
        send_notification "failed" "Database connection failed"
        exit 1
    fi
    
    # Perform backup
    if [ "$DB_TYPE" = "mysql" ]; then
        if backup_mysql; then
            backup_status="success"
        else
            backup_status="failed"
        fi
    elif [ "$DB_TYPE" = "postgresql" ]; then
        if backup_postgresql; then
            backup_status="success"
        else
            backup_status="failed"
        fi
    fi
    
    if [ "$backup_status" = "success" ]; then
        # Verify backup
        verify_backup
        
        # Manage retention
        manage_retention
        
        # List backups
        list_backups
        
        # Send success notification
        send_notification "success" "Database backup completed successfully"
        
        echo -e "${GREEN}✅ Backup completed successfully!${NC}\n"
        echo -e "${CYAN}💡 Tip: Add to cron for automatic backups:${NC}"
        echo -e "${YELLOW}0 2 * * * /path/to/day18_dbbackup.sh${NC}"
        echo -e "${CYAN}(Runs daily at 2 AM)${NC}\n"
    else
        send_notification "failed" "Database backup failed"
        echo -e "${RED}✗ Backup failed!${NC}\n"
        exit 1
    fi
}

# Run the script
main "$@"
