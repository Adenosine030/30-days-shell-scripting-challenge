
#!/bin/bash
#
# Day 19: SSH Connection Manager
# Author: Ademola Adenigba (CloudDemigod)
# Date: November 24, 2025
#
# Manages multiple SSH connections from a config file
# Execute commands on multiple servers simultaneously

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
CONFIG_FILE="$HOME/.ssh_manager/servers.conf"
LOG_FILE="$HOME/.ssh_manager/connection.log"

# Setup directories
setup_environment() {
    local config_dir=$(dirname "$CONFIG_FILE")
    
    if [ ! -d "$config_dir" ]; then
        mkdir -p "$config_dir"
        echo -e "${GREEN}✓ Created configuration directory${NC}\n"
    fi
    
    if [ ! -f "$CONFIG_FILE" ]; then
        create_sample_config
    fi
}

# Create sample configuration file
create_sample_config() {
    echo -e "${YELLOW}Creating sample configuration file...${NC}\n"
    
    cat > "$CONFIG_FILE" << 'EOF'
# SSH Connection Manager Configuration
# Format: alias,username,hostname,port,description
# Lines starting with # are comments

# Production Servers
prod-web1,ubuntu,192.168.1.10,22,Production Web Server 1
prod-web2,ubuntu,192.168.1.11,22,Production Web Server 2
prod-db,admin,192.168.1.20,22,Production Database Server

# Staging Servers
staging-web,ubuntu,192.168.2.10,22,Staging Web Server
staging-db,admin,192.168.2.20,22,Staging Database Server

# Development Servers
dev-server,dev,192.168.3.10,22,Development Server
test-server,tester,192.168.3.11,22,Testing Server

# Cloud Servers (AWS Example)
aws-prod,ec2-user,ec2-54-123-45-67.compute-1.amazonaws.com,22,AWS Production Server
aws-staging,ec2-user,ec2-54-123-45-68.compute-1.amazonaws.com,22,AWS Staging Server

# Special Servers
jump-host,admin,jumpbox.company.com,2222,Jump Server (Custom Port)
EOF
    
    echo -e "${GREEN}✓ Sample configuration created: $CONFIG_FILE${NC}"
    echo -e "${CYAN}Edit this file to add your actual servers${NC}\n"
}

# Print header
print_header() {
    clear
    echo -e "${CYAN}╔═══════════════════════════════════════════════════════════════╗${NC}"
    echo -e "${CYAN}║              SSH CONNECTION MANAGER                           ║${NC}"
    echo -e "${CYAN}║          Manage Multiple Server Connections                   ║${NC}"
    echo -e "${CYAN}╔═══════════════════════════════════════════════════════════════╗${NC}"
    echo -e "${BLUE}Configuration: $CONFIG_FILE${NC}\n"
}

# Function to parse config and display servers
list_servers() {
    echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo -e "${MAGENTA}🖥️  Available Servers${NC}"
    echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}\n"
    
    local index=1
    
    # Read and display servers
    while IFS=',' read -r alias username hostname port description; do
        # Skip comments and empty lines
        [[ "$alias" =~ ^#.*$ ]] && continue
        [[ -z "$alias" ]] && continue
        
        echo -e "${GREEN}[$index]${NC} ${CYAN}$alias${NC}"
        echo -e "    User: ${YELLOW}$username${NC}"
        echo -e "    Host: ${YELLOW}$hostname${NC}"
        echo -e "    Port: ${YELLOW}$port${NC}"
        echo -e "    Info: ${BLUE}$description${NC}"
        echo ""
        
        ((index++))
    done < "$CONFIG_FILE"
    
    local total=$((index - 1))
    echo -e "${CYAN}Total servers configured: $total${NC}\n"
}

# Function to connect to a server
connect_to_server() {
    local selection=$1
    
    if [ -z "$selection" ]; then
        read -p "Enter server number or alias: " selection
    fi
    
    local index=1
    local found=false
    
    # Search by number or alias
    while IFS=',' read -r alias username hostname port description; do
        # Skip comments and empty lines
        [[ "$alias" =~ ^#.*$ ]] && continue
        [[ -z "$alias" ]] && continue
        
        # Match by number or alias
        if [ "$index" -eq "$selection" ] 2>/dev/null || [ "$alias" = "$selection" ]; then
            found=true
            
            echo -e "\n${CYAN}Connecting to: ${GREEN}$alias${NC}"
            echo -e "${YELLOW}$username@$hostname:$port${NC}"
            echo -e "${BLUE}$description${NC}\n"
            
            # Log connection attempt
            log_connection "$alias" "$username" "$hostname" "$port"
            
            # Attempt SSH connection
            ssh -p "$port" "$username@$hostname"
            
            return $?
        fi
        
        ((index++))
    done < "$CONFIG_FILE"
    
    if [ "$found" = false ]; then
        echo -e "${RED}✗ Server not found: $selection${NC}\n"
        return 1
    fi
}

# Function to execute command on single server
execute_on_server() {
    local selection=$1
    local command=$2
    
    local index=1
    local found=false
    
    # Search by number or alias
    while IFS=',' read -r alias username hostname port description; do
        # Skip comments and empty lines
        [[ "$alias" =~ ^#.*$ ]] && continue
        [[ -z "$alias" ]] && continue
        
        # Match by number or alias
        if [ "$index" -eq "$selection" ] 2>/dev/null || [ "$alias" = "$selection" ]; then
            found=true
            
            echo -e "\n${CYAN}Executing on: ${GREEN}$alias${NC}"
            echo -e "${YELLOW}Command: $command${NC}\n"
            
            # Execute command via SSH
            ssh -p "$port" "$username@$hostname" "$command"
            
            local exit_code=$?
            
            if [ $exit_code -eq 0 ]; then
                echo -e "\n${GREEN}✓ Command completed successfully on $alias${NC}\n"
            else
                echo -e "\n${RED}✗ Command failed on $alias (Exit code: $exit_code)${NC}\n"
            fi
            
            return $exit_code
        fi
        
        ((index++))
    done < "$CONFIG_FILE"
    
    if [ "$found" = false ]; then
        echo -e "${RED}✗ Server not found: $selection${NC}\n"
        return 1
    fi
}

# Function to execute command on all servers
execute_on_all() {
    local command=$1
    
    echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo -e "${MAGENTA}⚡ Executing on All Servers${NC}"
    echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}\n"
    
    echo -e "${YELLOW}Command: $command${NC}\n"
    
    local success_count=0
    local fail_count=0
    
    # Execute on each server
    while IFS=',' read -r alias username hostname port description; do
        # Skip comments and empty lines
        [[ "$alias" =~ ^#.*$ ]] && continue
        [[ -z "$alias" ]] && continue
        
        echo -e "${CYAN}→ ${alias}${NC} ($username@$hostname)"
        
        # Execute command with timeout
        if timeout 30s ssh -o ConnectTimeout=10 -p "$port" "$username@$hostname" "$command" 2>/dev/null; then
            echo -e "${GREEN}  ✓ Success${NC}\n"
            ((success_count++))
        else
            echo -e "${RED}  ✗ Failed${NC}\n"
            ((fail_count++))
        fi
        
    done < "$CONFIG_FILE"
    
    # Summary
    echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo -e "${CYAN}Execution Summary:${NC}"
    echo -e "${GREEN}  Success: $success_count${NC}"
    echo -e "${RED}  Failed: $fail_count${NC}"
    echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}\n"
}

# Function to test connectivity to all servers
test_all_connections() {
    echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo -e "${MAGENTA}🔌 Testing All Connections${NC}"
    echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}\n"
    
    local reachable=0
    local unreachable=0
    
    while IFS=',' read -r alias username hostname port description; do
        # Skip comments and empty lines
        [[ "$alias" =~ ^#.*$ ]] && continue
        [[ -z "$alias" ]] && continue
        
        echo -ne "${CYAN}Testing ${alias}...${NC} "
        
        # Test SSH connection with timeout
        if timeout 10s ssh -o ConnectTimeout=5 -o BatchMode=yes -p "$port" "$username@$hostname" "exit" 2>/dev/null; then
            echo -e "${GREEN}✓ Reachable${NC}"
            ((reachable++))
        else
            echo -e "${RED}✗ Unreachable${NC}"
            ((unreachable++))
        fi
        
    done < "$CONFIG_FILE"
    
    echo -e "\n${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo -e "${CYAN}Connection Test Results:${NC}"
    echo -e "${GREEN}  Reachable: $reachable${NC}"
    echo -e "${RED}  Unreachable: $unreachable${NC}"
    echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}\n"
}

# Function to add new server
add_server() {
    echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo -e "${MAGENTA}➕ Add New Server${NC}"
    echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}\n"
    
    read -p "Alias (e.g., prod-web3): " alias
    read -p "Username: " username
    read -p "Hostname/IP: " hostname
    read -p "Port [22]: " port
    port=${port:-22}
    read -p "Description: " description
    
    # Validate inputs
    if [ -z "$alias" ] || [ -z "$username" ] || [ -z "$hostname" ]; then
        echo -e "\n${RED}✗ Error: Alias, username, and hostname are required${NC}\n"
        return 1
    fi
    
    # Check if alias already exists
    if grep -q "^$alias," "$CONFIG_FILE" 2>/dev/null; then
        echo -e "\n${RED}✗ Error: Alias '$alias' already exists${NC}\n"
        return 1
    fi
    
    # Add to config file
    echo "$alias,$username,$hostname,$port,$description" >> "$CONFIG_FILE"
    
    echo -e "\n${GREEN}✓ Server added successfully!${NC}\n"
    
    # Show the added server
    echo -e "${CYAN}Added:${NC}"
    echo -e "  Alias: ${GREEN}$alias${NC}"
    echo -e "  User: ${YELLOW}$username${NC}"
    echo -e "  Host: ${YELLOW}$hostname${NC}"
    echo -e "  Port: ${YELLOW}$port${NC}"
    echo -e "  Info: ${BLUE}$description${NC}\n"
}

# Function to remove server
remove_server() {
    echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo -e "${MAGENTA}➖ Remove Server${NC}"
    echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}\n"
    
    read -p "Enter server alias to remove: " alias
    
    if [ -z "$alias" ]; then
        echo -e "${RED}✗ Error: Alias is required${NC}\n"
        return 1
    fi
    
    # Check if exists
    if ! grep -q "^$alias," "$CONFIG_FILE" 2>/dev/null; then
        echo -e "${RED}✗ Error: Alias '$alias' not found${NC}\n"
        return 1
    fi
    
    # Confirm deletion
    echo -e "${YELLOW}Are you sure you want to remove '$alias'?${NC}"
    read -p "Type 'yes' to confirm: " confirm
    
    if [ "$confirm" = "yes" ]; then
        # Remove from config
        sed -i "/^$alias,/d" "$CONFIG_FILE" 2>/dev/null || sed -i '' "/^$alias,/d" "$CONFIG_FILE"
        echo -e "\n${GREEN}✓ Server removed successfully${NC}\n"
    else
        echo -e "\n${YELLOW}Removal cancelled${NC}\n"
    fi
}

# Function to log connections
log_connection() {
    local alias=$1
    local username=$2
    local hostname=$3
    local port=$4
    
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] Connected to $alias ($username@$hostname:$port)" >> "$LOG_FILE"
}

# Function to show connection logs
show_logs() {
    echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo -e "${MAGENTA}📋 Recent Connections${NC}"
    echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}\n"
    
    if [ -f "$LOG_FILE" ]; then
        tail -20 "$LOG_FILE"
    else
        echo -e "${YELLOW}No connection logs found${NC}"
    fi
    
    echo ""
}

# Function to show interactive menu
show_menu() {
    while true; do
        print_header
        list_servers
        
        echo -e "${CYAN}Options:${NC}"
        echo -e "  ${GREEN}1-N${NC}    Connect to server by number"
        echo -e "  ${GREEN}alias${NC}  Connect to server by alias"
        echo -e "  ${GREEN}cmd${NC}    Execute command on specific server"
        echo -e "  ${GREEN}all${NC}    Execute command on all servers"
        echo -e "  ${GREEN}test${NC}   Test connectivity to all servers"
        echo -e "  ${GREEN}add${NC}    Add new server"
        echo -e "  ${GREEN}remove${NC} Remove server"
        echo -e "  ${GREEN}logs${NC}   Show connection logs"
        echo -e "  ${GREEN}edit${NC}   Edit configuration file"
        echo -e "  ${GREEN}quit${NC}   Exit"
        echo ""
        
        read -p "Enter choice: " choice
        
        case "$choice" in
            quit|q|exit)
                echo -e "\n${GREEN}Goodbye!${NC}\n"
                exit 0
                ;;
            test)
                test_all_connections
                read -p "Press Enter to continue..."
                ;;
            cmd)
                read -p "Server number or alias: " server
                read -p "Command to execute: " command
                execute_on_server "$server" "$command"
                read -p "Press Enter to continue..."
                ;;
            all)
                read -p "Command to execute on all servers: " command
                execute_on_all "$command"
                read -p "Press Enter to continue..."
                ;;
            add)
                add_server
                read -p "Press Enter to continue..."
                ;;
            remove)
                remove_server
                read -p "Press Enter to continue..."
                ;;
            logs)
                show_logs
                read -p "Press Enter to continue..."
                ;;
            edit)
                ${EDITOR:-nano} "$CONFIG_FILE"
                ;;
            [0-9]*)
                connect_to_server "$choice"
                ;;
            *)
                connect_to_server "$choice"
                ;;
        esac
    done
}

# Function to show usage
print_usage() {
    echo -e "${CYAN}Usage:${NC}"
    echo -e "  $0 [OPTIONS]"
    echo -e ""
    echo -e "${CYAN}Options:${NC}"
    echo -e "  ${GREEN}-l, --list${NC}              List all configured servers"
    echo -e "  ${GREEN}-c, --connect${NC} ALIAS     Connect to server by alias"
    echo -e "  ${GREEN}-e, --execute${NC} ALIAS CMD Execute command on server"
    echo -e "  ${GREEN}-a, --all${NC} COMMAND       Execute command on all servers"
    echo -e "  ${GREEN}-t, --test${NC}              Test connectivity to all servers"
    echo -e "  ${GREEN}-i, --interactive${NC}       Interactive menu mode (default)"
    echo -e "  ${GREEN}--add${NC}                   Add new server"
    echo -e "  ${GREEN}--remove${NC} ALIAS          Remove server"
    echo -e "  ${GREEN}--logs${NC}                  Show connection logs"
    echo -e "  ${GREEN}-h, --help${NC}              Show this help message"
    echo -e ""
    echo -e "${CYAN}Examples:${NC}"
    echo -e "  $0                           # Interactive mode"
    echo -e "  $0 -l                        # List servers"
    echo -e "  $0 -c prod-web1              # Connect to prod-web1"
    echo -e "  $0 -e prod-web1 'uptime'     # Check uptime"
    echo -e "  $0 -a 'df -h'                # Check disk space on all"
    echo -e "  $0 -t                        # Test all connections"
    echo ""
}

# Main execution
main() {
    setup_environment
    
    # Parse command line arguments
    case "$1" in
        -l|--list)
            print_header
            list_servers
            ;;
        -c|--connect)
            print_header
            connect_to_server "$2"
            ;;
        -e|--execute)
            print_header
            execute_on_server "$2" "$3"
            ;;
        -a|--all)
            print_header
            execute_on_all "$2"
            ;;
        -t|--test)
            print_header
            test_all_connections
            ;;
        --add)
            print_header
            add_server
            ;;
        --remove)
            print_header
            remove_server
            ;;
        --logs)
            print_header
            show_logs
            ;;
        -i|--interactive|"")
            show_menu
            ;;
        -h|--help)
            print_header
            print_usage
            ;;
        *)
            print_header
            echo -e "${RED}Unknown option: $1${NC}\n"
            print_usage
            exit 1
            ;;
    esac
}

# Run the script
main "$@"
