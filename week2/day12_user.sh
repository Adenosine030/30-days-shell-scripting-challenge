#!/bin/bash
#
# Day 12: User Management Script
# Author: Ademola Adenigba (CloudDemigod)
# Date: November 17, 2025
#
# Automates user management operations with command-line flags
# Usage: ./day12_users.sh -c username  # Create user
#        ./day12_users.sh -d username  # Delete user
#        ./day12_users.sh -l           # List all users
#        ./day12_users.sh -e username  # Check if user exists

# Color codes for output
RED='\033[0;31m'
YELLOW='\033[1;33m'
GREEN='\033[0;32m'
BLUE='\033[0;34m'
MAGENTA='\033[0;35m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

# Script must be run as root
check_root() {
    if [ "$EUID" -ne 0 ]; then
        echo -e "${RED}Error: This script must be run as root or with sudo${NC}"
        echo -e "${YELLOW}Usage: sudo $0 [options]${NC}"
        exit 1
    fi
}

# Function to print usage
print_usage() {
    echo -e "\n${CYAN}╔═══════════════════════════════════════════════════════════════╗${NC}"
    echo -e "${CYAN}║              USER MANAGEMENT SCRIPT                           ║${NC}"
    echo -e "${CYAN}╚═══════════════════════════════════════════════════════════════╝${NC}\n"
    
    echo -e "${BLUE}Usage:${NC}"
    echo -e "  $0 ${GREEN}-c${NC} USERNAME           Create a new user"
    echo -e "  $0 ${GREEN}-d${NC} USERNAME           Delete an existing user"
    echo -e "  $0 ${GREEN}-l${NC}                    List all regular users"
    echo -e "  $0 ${GREEN}-e${NC} USERNAME           Check if user exists"
    echo -e "  $0 ${GREEN}-h${NC}                    Display this help message"
    
    echo -e "\n${BLUE}Examples:${NC}"
    echo -e "  ${YELLOW}sudo $0 -c john${NC}        # Create user 'john'"
    echo -e "  ${YELLOW}sudo $0 -e john${NC}        # Check if 'john' exists"
    echo -e "  ${YELLOW}sudo $0 -l${NC}             # List all users"
    echo -e "  ${YELLOW}sudo $0 -d john${NC}        # Delete user 'john'"
    
    echo ""
}

# Function to log actions
log_action() {
    local action=$1
    local username=$2
    local status=$3
    local log_file="/var/log/user_management.log"
    
    # Create log file if it doesn't exist
    touch "$log_file" 2>/dev/null
    
    # Log the action
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $action: $username - $status" >> "$log_file" 2>/dev/null
}

# Function to create user
create_user() {
    local username=$1
    
    echo -e "\n${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo -e "${MAGENTA}🔨 Creating User: ${CYAN}$username${NC}"
    echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}\n"
    
    # Check if user already exists
    if id "$username" &>/dev/null; then
        echo -e "${RED}✗ Error: User '$username' already exists!${NC}"
        log_action "CREATE_FAILED" "$username" "User already exists"
        return 1
    fi
    
    # Validate username (alphanumeric, underscore, hyphen only)
    if ! [[ "$username" =~ ^[a-z_][a-z0-9_-]*$ ]]; then
        echo -e "${RED}✗ Error: Invalid username format!${NC}"
        echo -e "${YELLOW}Username must start with a letter or underscore${NC}"
        echo -e "${YELLOW}and contain only lowercase letters, numbers, underscore, or hyphen${NC}"
        log_action "CREATE_FAILED" "$username" "Invalid username format"
        return 1
    fi
    
    # Create the user
    if useradd -m -s /bin/bash "$username" 2>/dev/null; then
        echo -e "${GREEN}✓ User '$username' created successfully!${NC}"
        
        # Set password
        echo -e "\n${YELLOW}Setting password for $username:${NC}"
        if passwd "$username"; then
            echo -e "${GREEN}✓ Password set successfully!${NC}"
        else
            echo -e "${RED}✗ Warning: Password not set!${NC}"
        fi
        
        # Display user information
        echo -e "\n${CYAN}User Information:${NC}"
        echo -e "  ${BLUE}Username:${NC}     $username"
        echo -e "  ${BLUE}UID:${NC}          $(id -u $username)"
        echo -e "  ${BLUE}GID:${NC}          $(id -g $username)"
        echo -e "  ${BLUE}Home Dir:${NC}     $(eval echo ~$username)"
        echo -e "  ${BLUE}Shell:${NC}        $(getent passwd $username | cut -d: -f7)"
        
        log_action "CREATE_SUCCESS" "$username" "User created successfully"
        echo -e "\n${GREEN}✓ User creation completed!${NC}\n"
        return 0
    else
        echo -e "${RED}✗ Error: Failed to create user '$username'${NC}"
        log_action "CREATE_FAILED" "$username" "useradd command failed"
        return 1
    fi
}

# Function to delete user
delete_user() {
    local username=$1
    
    echo -e "\n${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo -e "${MAGENTA}🗑️  Deleting User: ${CYAN}$username${NC}"
    echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}\n"
    
    # Check if user exists
    if ! id "$username" &>/dev/null; then
        echo -e "${RED}✗ Error: User '$username' does not exist!${NC}"
        log_action "DELETE_FAILED" "$username" "User does not exist"
        return 1
    fi
    
    # Prevent deletion of system users (UID < 1000)
    local uid=$(id -u "$username")
    if [ "$uid" -lt 1000 ]; then
        echo -e "${RED}✗ Error: Cannot delete system user (UID < 1000)!${NC}"
        log_action "DELETE_FAILED" "$username" "System user protection"
        return 1
    fi
    
    # Confirm deletion
    echo -e "${YELLOW}⚠️  WARNING: This will delete user '$username' and their home directory!${NC}"
    read -p "Are you sure? (yes/no): " confirmation
    
    if [ "$confirmation" != "yes" ]; then
        echo -e "${YELLOW}✓ Deletion cancelled${NC}"
        log_action "DELETE_CANCELLED" "$username" "User cancelled operation"
        return 0
    fi
    
    # Delete the user and home directory
    if userdel -r "$username" 2>/dev/null; then
        echo -e "${GREEN}✓ User '$username' deleted successfully!${NC}"
        echo -e "${GREEN}✓ Home directory removed${NC}"
        log_action "DELETE_SUCCESS" "$username" "User and home directory deleted"
        echo ""
        return 0
    else
        echo -e "${RED}✗ Error: Failed to delete user '$username'${NC}"
        log_action "DELETE_FAILED" "$username" "userdel command failed"
        return 1
    fi
}

# Function to list all regular users
list_users() {
    echo -e "\n${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo -e "${MAGENTA}👥 Regular Users (UID >= 1000)${NC}"
    echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}\n"
    
    # Get regular users (UID >= 1000, excluding nobody)
    local user_count=0
    
    echo -e "${CYAN}Username${NC}          ${CYAN}UID${NC}    ${CYAN}GID${NC}    ${CYAN}Home Directory${NC}                ${CYAN}Shell${NC}"
    echo -e "${BLUE}────────────────────────────────────────────────────────────────────────────${NC}"
    
    while IFS=: read -r username _ uid gid _ homedir shell; do
        if [ "$uid" -ge 1000 ] && [ "$username" != "nobody" ] && [ "$uid" -lt 65534 ]; then
            printf "${GREEN}%-15s${NC} %-6s %-6s %-30s %-20s\n" \
                "$username" "$uid" "$gid" "$homedir" "$shell"
            ((user_count++))
        fi
    done < /etc/passwd
    
    echo -e "${BLUE}────────────────────────────────────────────────────────────────────────────${NC}"
    echo -e "${YELLOW}Total regular users: $user_count${NC}\n"
    
    log_action "LIST_USERS" "N/A" "Listed $user_count users"
}

# Function to check if user exists
check_user() {
    local username=$1
    
    echo -e "\n${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo -e "${MAGENTA}🔍 Checking User: ${CYAN}$username${NC}"
    echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}\n"
    
    if id "$username" &>/dev/null; then
        echo -e "${GREEN}✓ User '$username' exists!${NC}\n"
        
        # Display detailed information
        echo -e "${CYAN}User Details:${NC}"
        echo -e "  ${BLUE}Username:${NC}       $username"
        echo -e "  ${BLUE}UID:${NC}            $(id -u $username)"
        echo -e "  ${BLUE}GID:${NC}            $(id -g $username)"
        echo -e "  ${BLUE}Groups:${NC}         $(id -Gn $username)"
        echo -e "  ${BLUE}Home Directory:${NC} $(eval echo ~$username)"
        echo -e "  ${BLUE}Shell:${NC}          $(getent passwd $username | cut -d: -f7)"
        
        # Check if home directory exists
        local homedir=$(eval echo ~$username)
        if [ -d "$homedir" ]; then
            echo -e "  ${BLUE}Home Exists:${NC}    ${GREEN}Yes${NC}"
        else
            echo -e "  ${BLUE}Home Exists:${NC}    ${RED}No${NC}"
        fi
        
        # Check last login
        local last_login=$(lastlog -u $username 2>/dev/null | tail -1 | awk '{print $4, $5, $6, $7, $8, $9}')
        if [ ! -z "$last_login" ] && [ "$last_login" != "**Never logged in**" ]; then
            echo -e "  ${BLUE}Last Login:${NC}     $last_login"
        else
            echo -e "  ${BLUE}Last Login:${NC}     ${YELLOW}Never${NC}"
        fi
        
        log_action "CHECK_USER" "$username" "User exists"
        echo ""
        return 0
    else
        echo -e "${RED}✗ User '$username' does not exist!${NC}\n"
        log_action "CHECK_USER" "$username" "User does not exist"
        return 1
    fi
}

# Main script execution
main() {
    # Check if running as root (except for help and list)
    if [ "$1" != "-h" ] && [ "$1" != "-l" ]; then
        check_root
    fi
    
    # Parse command line arguments
    if [ $# -eq 0 ]; then
        print_usage
        exit 1
    fi
    
    case "$1" in
        -c|--create)
            if [ -z "$2" ]; then
                echo -e "${RED}Error: Username required for create operation${NC}"
                print_usage
                exit 1
            fi
            create_user "$2"
            ;;
        -d|--delete)
            if [ -z "$2" ]; then
                echo -e "${RED}Error: Username required for delete operation${NC}"
                print_usage
                exit 1
            fi
            delete_user "$2"
            ;;
        -l|--list)
            list_users
            ;;
        -e|--exists)
            if [ -z "$2" ]; then
                echo -e "${RED}Error: Username required for existence check${NC}"
                print_usage
                exit 1
            fi
            check_user "$2"
            ;;
        -h|--help)
            print_usage
            exit 0
            ;;
        *)
            echo -e "${RED}Error: Invalid option '$1'${NC}"
            print_usage
            exit 1
            ;;
    esac
}

# Run the main function
main "$@"
