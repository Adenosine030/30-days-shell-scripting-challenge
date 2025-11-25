
#!/bin/bash
#
# Day 20: Docker Helper Script
# Author: Ademola Adenigba (CloudDemigod)
# Date: November 25, 2025
#
# Docker automation and management tool
# Cleanup, monitoring, and container management made easy!

# Color codes
RED='\033[0;31m'
YELLOW='\033[1;33m'
GREEN='\033[0;32m'
BLUE='\033[0;34m'
MAGENTA='\033[0;35m'
CYAN='\033[0;36m'
BOLD='\033[1m'
NC='\033[0m'

# Check if Docker is installed
check_docker() {
    if ! command -v docker &> /dev/null; then
        echo -e "${RED}✗ Docker is not installed!${NC}"
        echo -e "${YELLOW}Install Docker:${NC}"
        echo -e "  Ubuntu: curl -fsSL https://get.docker.com | sh"
        echo -e "  Mac: brew install docker"
        echo -e "  Or visit: https://docs.docker.com/get-docker/"
        exit 1
    fi
    
    # Check if Docker daemon is running
    if ! docker ps &> /dev/null; then
        echo -e "${RED}✗ Docker daemon is not running!${NC}"
        echo -e "${YELLOW}Start Docker:${NC}"
        echo -e "  Linux: sudo systemctl start docker"
        echo -e "  Mac: Open Docker Desktop"
        exit 1
    fi
}

# Print header
print_header() {
    clear
    echo -e "${CYAN}╔═══════════════════════════════════════════════════════════════╗${NC}"
    echo -e "${CYAN}║              DOCKER HELPER SCRIPT                             ║${NC}"
    echo -e "${CYAN}║         Container Management Made Easy                        ║${NC}"
    echo -e "${CYAN}╔═══════════════════════════════════════════════════════════════╗${NC}"
    echo -e "${BLUE}Docker Version: $(docker --version 2>/dev/null | cut -d' ' -f3 | cut -d',' -f1)${NC}\n"
}

# Function to get human-readable size
get_human_size() {
    local bytes=$1
    
    if [ -z "$bytes" ] || [ "$bytes" = "0" ]; then
        echo "0 B"
        return
    fi
    
    # Remove any units if present
    bytes=$(echo "$bytes" | sed 's/[^0-9.]//g')
    
    if (( $(echo "$bytes >= 1073741824" | bc -l) )); then
        printf "%.2f GB" $(echo "scale=2; $bytes / 1073741824" | bc)
    elif (( $(echo "$bytes >= 1048576" | bc -l) )); then
        printf "%.2f MB" $(echo "scale=2; $bytes / 1048576" | bc)
    elif (( $(echo "$bytes >= 1024" | bc -l) )); then
        printf "%.2f KB" $(echo "scale=2; $bytes / 1024" | bc)
    else
        printf "%d B" $bytes
    fi
}

# Function to list all containers
list_containers() {
    echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo -e "${MAGENTA}📦 Docker Containers${NC}"
    echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}\n"
    
    # Get container counts
    local running=$(docker ps -q 2>/dev/null | wc -l)
    local stopped=$(docker ps -aq -f status=exited 2>/dev/null | wc -l)
    local total=$(docker ps -aq 2>/dev/null | wc -l)
    
    echo -e "${CYAN}Total Containers: ${YELLOW}$total${NC}"
    echo -e "${GREEN}Running: ${YELLOW}$running${NC}"
    echo -e "${RED}Stopped: ${YELLOW}$stopped${NC}\n"
    
    if [ $total -eq 0 ]; then
        echo -e "${YELLOW}No containers found${NC}\n"
        return
    fi
    
    echo -e "${CYAN}${BOLD}Running Containers:${NC}"
    if [ $running -gt 0 ]; then
        docker ps --format "table {{.Names}}\t{{.Image}}\t{{.Status}}\t{{.Ports}}" | while IFS= read -r line; do
            if [[ "$line" =~ ^NAMES ]]; then
                echo -e "${BLUE}$line${NC}"
            else
                echo -e "${GREEN}✓${NC} $line"
            fi
        done
    else
        echo -e "${YELLOW}  No running containers${NC}"
    fi
    
    echo ""
    
    echo -e "${CYAN}${BOLD}Stopped Containers:${NC}"
    if [ $stopped -gt 0 ]; then
        docker ps -a -f status=exited --format "table {{.Names}}\t{{.Image}}\t{{.Status}}" | while IFS= read -r line; do
            if [[ "$line" =~ ^NAMES ]]; then
                echo -e "${BLUE}$line${NC}"
            else
                echo -e "${RED}✗${NC} $line"
            fi
        done
    else
        echo -e "${GREEN}  No stopped containers${NC}"
    fi
    
    echo ""
}

# Function to clean up stopped containers
cleanup_containers() {
    echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo -e "${MAGENTA}🧹 Removing Stopped Containers${NC}"
    echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}\n"
    
    local stopped_count=$(docker ps -aq -f status=exited 2>/dev/null | wc -l)
    
    if [ $stopped_count -eq 0 ]; then
        echo -e "${GREEN}✓ No stopped containers to remove${NC}\n"
        return
    fi
    
    echo -e "${YELLOW}Found $stopped_count stopped container(s)${NC}\n"
    
    # List stopped containers
    docker ps -a -f status=exited --format "  • {{.Names}} ({{.Image}})"
    
    echo ""
    read -p "Remove all stopped containers? (yes/no): " confirm
    
    if [ "$confirm" = "yes" ]; then
        echo -e "\n${YELLOW}Removing stopped containers...${NC}\n"
        
        if docker container prune -f 2>/dev/null; then
            echo -e "${GREEN}✓ Successfully removed $stopped_count stopped container(s)${NC}\n"
        else
            echo -e "${RED}✗ Failed to remove containers${NC}\n"
        fi
    else
        echo -e "\n${YELLOW}Cleanup cancelled${NC}\n"
    fi
}

# Function to list and manage images
list_images() {
    echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo -e "${MAGENTA}🖼️  Docker Images${NC}"
    echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}\n"
    
    local total_images=$(docker images -q 2>/dev/null | wc -l)
    local dangling=$(docker images -f "dangling=true" -q 2>/dev/null | wc -l)
    
    echo -e "${CYAN}Total Images: ${YELLOW}$total_images${NC}"
    echo -e "${RED}Dangling Images: ${YELLOW}$dangling${NC}\n"
    
    if [ $total_images -eq 0 ]; then
        echo -e "${YELLOW}No images found${NC}\n"
        return
    fi
    
    echo -e "${CYAN}${BOLD}All Images:${NC}"
    docker images --format "table {{.Repository}}\t{{.Tag}}\t{{.Size}}\t{{.CreatedAt}}" | while IFS= read -r line; do
        if [[ "$line" =~ ^REPOSITORY ]]; then
            echo -e "${BLUE}$line${NC}"
        else
            echo -e "${GREEN}•${NC} $line"
        fi
    done
    
    echo ""
}

# Function to clean up unused images
cleanup_images() {
    echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo -e "${MAGENTA}🧹 Removing Unused Images${NC}"
    echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}\n"
    
    local dangling=$(docker images -f "dangling=true" -q 2>/dev/null | wc -l)
    
    if [ $dangling -eq 0 ]; then
        echo -e "${GREEN}✓ No dangling images to remove${NC}\n"
    else
        echo -e "${YELLOW}Found $dangling dangling image(s)${NC}\n"
        
        read -p "Remove dangling images? (yes/no): " confirm
        
        if [ "$confirm" = "yes" ]; then
            echo -e "\n${YELLOW}Removing dangling images...${NC}\n"
            
            if docker image prune -f 2>/dev/null; then
                echo -e "${GREEN}✓ Successfully removed dangling images${NC}\n"
            else
                echo -e "${RED}✗ Failed to remove images${NC}\n"
            fi
        else
            echo -e "\n${YELLOW}Cleanup cancelled${NC}\n"
        fi
    fi
    
    # Check for unused images
    echo -e "${CYAN}Remove ALL unused images (not just dangling)?${NC}"
    read -p "This includes images not referenced by any container (yes/no): " confirm_all
    
    if [ "$confirm_all" = "yes" ]; then
        echo -e "\n${YELLOW}Removing all unused images...${NC}\n"
        
        if docker image prune -a -f 2>/dev/null; then
            echo -e "${GREEN}✓ Successfully removed unused images${NC}\n"
        else
            echo -e "${RED}✗ Failed to remove images${NC}\n"
        fi
    fi
}

# Function to show disk usage
show_disk_usage() {
    echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo -e "${MAGENTA}💾 Docker Disk Usage${NC}"
    echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}\n"
    
    # Run docker system df
    docker system df --format "table {{.Type}}\t{{.TotalCount}}\t{{.Size}}\t{{.Reclaimable}}"
    
    echo ""
    
    # Get total reclaimable space
    local reclaimable=$(docker system df --format "{{.Reclaimable}}" | grep -o '[0-9.]*[KMGT]*B' | head -1)
    
    if [ ! -z "$reclaimable" ]; then
        echo -e "${YELLOW}Total Reclaimable Space: ${RED}$reclaimable${NC}\n"
    fi
}

# Function to perform full system prune
full_cleanup() {
    echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo -e "${MAGENTA}🔥 Full System Cleanup${NC}"
    echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}\n"
    
    echo -e "${RED}${BOLD}WARNING: This will remove:${NC}"
    echo -e "${YELLOW}  • All stopped containers${NC}"
    echo -e "${YELLOW}  • All networks not used by at least one container${NC}"
    echo -e "${YELLOW}  • All dangling images${NC}"
    echo -e "${YELLOW}  • All dangling build cache${NC}"
    echo ""
    
    # Show what will be freed
    show_disk_usage
    
    read -p "Proceed with full cleanup? (yes/no): " confirm
    
    if [ "$confirm" = "yes" ]; then
        echo -e "\n${YELLOW}Performing full system prune...${NC}\n"
        
        # Capture output
        local output=$(docker system prune -f 2>&1)
        
        echo "$output"
        
        # Extract space reclaimed
        local reclaimed=$(echo "$output" | grep "Total reclaimed space" | awk '{print $4, $5}')
        
        if [ ! -z "$reclaimed" ]; then
            echo -e "\n${GREEN}✓ Space reclaimed: ${CYAN}$reclaimed${NC}\n"
        else
            echo -e "\n${GREEN}✓ Cleanup completed${NC}\n"
        fi
    else
        echo -e "\n${YELLOW}Cleanup cancelled${NC}\n"
    fi
}

# Function to show container logs
show_container_logs() {
    echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo -e "${MAGENTA}📋 Container Logs${NC}"
    echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}\n"
    
    # List running containers
    local running=$(docker ps --format "{{.Names}}" | wc -l)
    
    if [ $running -eq 0 ]; then
        echo -e "${YELLOW}No running containers${NC}\n"
        return
    fi
    
    echo -e "${CYAN}Running Containers:${NC}\n"
    
    local index=1
    docker ps --format "{{.Names}}" | while read container; do
        echo -e "  ${GREEN}[$index]${NC} $container"
        ((index++))
    done
    
    echo ""
    read -p "Enter container number or name: " selection
    
    # Get container name
    local container_name=""
    if [[ "$selection" =~ ^[0-9]+$ ]]; then
        container_name=$(docker ps --format "{{.Names}}" | sed -n "${selection}p")
    else
        container_name="$selection"
    fi
    
    if [ -z "$container_name" ]; then
        echo -e "${RED}✗ Invalid selection${NC}\n"
        return
    fi
    
    echo -e "\n${CYAN}Logs for: ${GREEN}$container_name${NC}\n"
    echo -e "${YELLOW}Press Ctrl+C to stop following logs${NC}\n"
    
    sleep 2
    
    # Show last 50 lines and follow
    docker logs --tail 50 -f "$container_name"
}

# Function to show container stats
show_container_stats() {
    echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo -e "${MAGENTA}📊 Container Resource Usage${NC}"
    echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}\n"
    
    local running=$(docker ps -q | wc -l)
    
    if [ $running -eq 0 ]; then
        echo -e "${YELLOW}No running containers${NC}\n"
        return
    fi
    
    echo -e "${CYAN}Real-time resource usage (Press Ctrl+C to exit)${NC}\n"
    
    sleep 2
    
    # Show stats
    docker stats --no-stream --format "table {{.Name}}\t{{.CPUPerc}}\t{{.MemUsage}}\t{{.NetIO}}\t{{.BlockIO}}"
}

# Function to start/stop containers
manage_container() {
    local action=$1
    
    echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo -e "${MAGENTA}🎮 Container Management - ${action^^}${NC}"
    echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}\n"
    
    if [ "$action" = "start" ]; then
        local containers=$(docker ps -a -f status=exited --format "{{.Names}}" | wc -l)
        
        if [ $containers -eq 0 ]; then
            echo -e "${YELLOW}No stopped containers to start${NC}\n"
            return
        fi
        
        echo -e "${CYAN}Stopped Containers:${NC}\n"
        
        local index=1
        docker ps -a -f status=exited --format "{{.Names}}" | while read container; do
            echo -e "  ${RED}[$index]${NC} $container"
            ((index++))
        done
        
    elif [ "$action" = "stop" ]; then
        local containers=$(docker ps --format "{{.Names}}" | wc -l)
        
        if [ $containers -eq 0 ]; then
            echo -e "${YELLOW}No running containers to stop${NC}\n"
            return
        fi
        
        echo -e "${CYAN}Running Containers:${NC}\n"
        
        local index=1
        docker ps --format "{{.Names}}" | while read container; do
            echo -e "  ${GREEN}[$index]${NC} $container"
            ((index++))
        done
    fi
    
    echo ""
    read -p "Enter container number, name, or 'all': " selection
    
    if [ "$selection" = "all" ]; then
        read -p "Are you sure you want to $action ALL containers? (yes/no): " confirm
        
        if [ "$confirm" = "yes" ]; then
            echo -e "\n${YELLOW}${action^}ing all containers...${NC}\n"
            
            if [ "$action" = "start" ]; then
                docker start $(docker ps -aq -f status=exited) 2>/dev/null && \
                    echo -e "${GREEN}✓ All containers started${NC}\n"
            elif [ "$action" = "stop" ]; then
                docker stop $(docker ps -q) 2>/dev/null && \
                    echo -e "${GREEN}✓ All containers stopped${NC}\n"
            fi
        fi
    else
        # Get container name
        local container_name=""
        if [[ "$selection" =~ ^[0-9]+$ ]]; then
            if [ "$action" = "start" ]; then
                container_name=$(docker ps -a -f status=exited --format "{{.Names}}" | sed -n "${selection}p")
            else
                container_name=$(docker ps --format "{{.Names}}" | sed -n "${selection}p")
            fi
        else
            container_name="$selection"
        fi
        
        if [ -z "$container_name" ]; then
            echo -e "${RED}✗ Invalid selection${NC}\n"
            return
        fi
        
        echo -e "\n${YELLOW}${action^}ing container: $container_name${NC}\n"
        
        if docker "$action" "$container_name" 2>/dev/null; then
            echo -e "${GREEN}✓ Container ${action}ed successfully${NC}\n"
        else
            echo -e "${RED}✗ Failed to $action container${NC}\n"
        fi
    fi
}

# Function to show interactive menu
show_menu() {
    while true; do
        print_header
        
        echo -e "${CYAN}${BOLD}Main Menu:${NC}\n"
        echo -e "  ${GREEN}1${NC}) List all containers"
        echo -e "  ${GREEN}2${NC}) List all images"
        echo -e "  ${GREEN}3${NC}) Show disk usage"
        echo -e "  ${GREEN}4${NC}) Container stats (CPU/Memory)"
        echo -e "  ${GREEN}5${NC}) View container logs"
        echo -e "  ${GREEN}6${NC}) Start containers"
        echo -e "  ${GREEN}7${NC}) Stop containers"
        echo -e ""
        echo -e "  ${YELLOW}8${NC}) Remove stopped containers"
        echo -e "  ${YELLOW}9${NC}) Remove unused images"
        echo -e "  ${RED}10${NC}) Full system cleanup"
        echo -e ""
        echo -e "  ${BLUE}q${NC}) Quit"
        echo ""
        
        read -p "Enter choice: " choice
        
        case "$choice" in
            1)
                print_header
                list_containers
                read -p "Press Enter to continue..."
                ;;
            2)
                print_header
                list_images
                read -p "Press Enter to continue..."
                ;;
            3)
                print_header
                show_disk_usage
                read -p "Press Enter to continue..."
                ;;
            4)
                print_header
                show_container_stats
                ;;
            5)
                print_header
                show_container_logs
                ;;
            6)
                print_header
                manage_container "start"
                read -p "Press Enter to continue..."
                ;;
            7)
                print_header
                manage_container "stop"
                read -p "Press Enter to continue..."
                ;;
            8)
                print_header
                cleanup_containers
                read -p "Press Enter to continue..."
                ;;
            9)
                print_header
                cleanup_images
                read -p "Press Enter to continue..."
                ;;
            10)
                print_header
                full_cleanup
                read -p "Press Enter to continue..."
                ;;
            q|Q|quit|exit)
                echo -e "\n${GREEN}Goodbye!${NC}\n"
                exit 0
                ;;
            *)
                echo -e "\n${RED}Invalid choice${NC}\n"
                sleep 1
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
    echo -e "  ${GREEN}-l, --list${NC}       List all containers"
    echo -e "  ${GREEN}-i, --images${NC}     List all images"
    echo -e "  ${GREEN}-d, --disk${NC}       Show disk usage"
    echo -e "  ${GREEN}-s, --stats${NC}      Show container stats"
    echo -e "  ${GREEN}-c, --cleanup${NC}    Remove stopped containers"
    echo -e "  ${GREEN}-p, --prune${NC}      Full system cleanup"
    echo -e "  ${GREEN}-m, --menu${NC}       Interactive menu (default)"
    echo -e "  ${GREEN}-h, --help${NC}       Show this help"
    echo -e ""
    echo -e "${CYAN}Examples:${NC}"
    echo -e "  $0                # Interactive menu"
    echo -e "  $0 -l             # List containers"
    echo -e "  $0 -d             # Show disk usage"
    echo -e "  $0 -c             # Cleanup stopped containers"
    echo ""
}

# Main execution
main() {
    check_docker
    
    case "$1" in
        -l|--list)
            print_header
            list_containers
            ;;
        -i|--images)
            print_header
            list_images
            ;;
        -d|--disk)
            print_header
            show_disk_usage
            ;;
        -s|--stats)
            print_header
            show_container_stats
            ;;
        -c|--cleanup)
            print_header
            cleanup_containers
            ;;
        -p|--prune)
            print_header
            full_cleanup
            ;;
        -m|--menu|"")
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
