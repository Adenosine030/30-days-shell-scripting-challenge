#!/bin/bash
#
# Day 14: Advanced File Search Tool
# Author: Ademola Adenigba (CloudDemigod)
# Date: November 18, 2025
#
# Powerful file search with multiple criteria: name, size, and modification date
# Usage: ./day14_search.sh -n "*.log" -s 10 -d 7

# Color codes
RED='\033[0;31m'
YELLOW='\033[1;33m'
GREEN='\033[0;32m'
BLUE='\033[0;34m'
MAGENTA='\033[0;35m'
CYAN='\033[0;36m'
BOLD='\033[1m'
NC='\033[0m'

# Global variables
SEARCH_NAME=""
SEARCH_SIZE=""
SEARCH_DAYS=""
SEARCH_PATH="."
CASE_SENSITIVE=false
SEARCH_TYPE="f"  # f=files, d=directories, a=all

# Function to print header
print_header() {
    clear
    echo -e "${CYAN}╔═══════════════════════════════════════════════════════════════╗${NC}"
    echo -e "${CYAN}║           ADVANCED FILE SEARCH TOOL                           ║${NC}"
    echo -e "${CYAN}║     Find files by name, size, and modification date           ║${NC}"
    echo -e "${CYAN}╔═══════════════════════════════════════════════════════════════╗${NC}\n"
}

# Function to print usage
print_usage() {
    echo -e "${BLUE}Usage:${NC}"
    echo -e "  $0 [OPTIONS]"
    echo -e ""
    echo -e "${BLUE}Search Options:${NC}"
    echo -e "  ${GREEN}-n${NC} PATTERN        Search by name pattern (e.g., '*.log', 'config*')"
    echo -e "  ${GREEN}-s${NC} SIZE           Search files larger than SIZE MB"
    echo -e "  ${GREEN}-d${NC} DAYS           Search files modified in last DAYS days"
    echo -e "  ${GREEN}-p${NC} PATH           Search path (default: current directory)"
    echo -e "  ${GREEN}-t${NC} TYPE           Search type: f(files), d(dirs), a(all) [default: f]"
    echo -e "  ${GREEN}-i${NC}                Case-insensitive name search"
    echo -e ""
    echo -e "${BLUE}Display Options:${NC}"
    echo -e "  ${GREEN}-h${NC}                Show this help message"
    echo -e "  ${GREEN}-v${NC}                Verbose output with detailed info"
    echo -e ""
    echo -e "${BLUE}Examples:${NC}"
    echo -e "  ${YELLOW}# Find all .log files${NC}"
    echo -e "  $0 -n '*.log'"
    echo -e ""
    echo -e "  ${YELLOW}# Find files larger than 10MB${NC}"
    echo -e "  $0 -s 10"
    echo -e ""
    echo -e "  ${YELLOW}# Find files modified in last 7 days${NC}"
    echo -e "  $0 -d 7"
    echo -e ""
    echo -e "  ${YELLOW}# Combine: Find .log files > 10MB modified in last 7 days${NC}"
    echo -e "  $0 -n '*.log' -s 10 -d 7"
    echo -e ""
    echo -e "  ${YELLOW}# Search in specific directory${NC}"
    echo -e "  $0 -n '*.txt' -p /var/log"
    echo -e ""
    echo -e "  ${YELLOW}# Find directories only${NC}"
    echo -e "  $0 -t d -n 'project*'"
    echo -e ""
}

# Function to convert bytes to human-readable
bytes_to_human() {
    local bytes=$1
    local sizes=("B" "KB" "MB" "GB" "TB")
    local size_index=0
    local size=$bytes
    
    while (( $(echo "$size >= 1024" | bc -l) )) && [ $size_index -lt 4 ]; do
        size=$(echo "scale=2; $size / 1024" | bc)
        ((size_index++))
    done
    
    printf "%.2f %s" "$size" "${sizes[$size_index]}"
}

# Function to get file age in days
get_file_age_days() {
    local file=$1
    local current_time=$(date +%s)
    local file_time=$(stat -c %Y "$file" 2>/dev/null || stat -f %m "$file" 2>/dev/null)
    local age_seconds=$((current_time - file_time))
    local age_days=$((age_seconds / 86400))
    echo $age_days
}

# Function to format date
format_date() {
    local timestamp=$1
    date -d "@$timestamp" "+%Y-%m-%d %H:%M:%S" 2>/dev/null || date -r "$timestamp" "+%Y-%m-%d %H:%M:%S" 2>/dev/null
}

# Function to build find command
build_find_command() {
    local cmd="find \"$SEARCH_PATH\""
    
    # Add type filter
    if [ "$SEARCH_TYPE" = "f" ]; then
        cmd="$cmd -type f"
    elif [ "$SEARCH_TYPE" = "d" ]; then
        cmd="$cmd -type d"
    fi
    
    # Add name pattern
    if [ ! -z "$SEARCH_NAME" ]; then
        if [ "$CASE_SENSITIVE" = true ]; then
            cmd="$cmd -name \"$SEARCH_NAME\""
        else
            cmd="$cmd -iname \"$SEARCH_NAME\""
        fi
    fi
    
    # Add size filter (convert MB to bytes for find command)
    if [ ! -z "$SEARCH_SIZE" ]; then
        cmd="$cmd -size +${SEARCH_SIZE}M"
    fi
    
    # Add modification time filter
    if [ ! -z "$SEARCH_DAYS" ]; then
        cmd="$cmd -mtime -${SEARCH_DAYS}"
    fi
    
    echo "$cmd"
}

# Function to search files
search_files() {
    echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo -e "${MAGENTA}🔍 Search Criteria${NC}"
    echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}\n"
    
    echo -e "${CYAN}Search Path:${NC}      $SEARCH_PATH"
    echo -e "${CYAN}Search Type:${NC}      $([ "$SEARCH_TYPE" = "f" ] && echo "Files" || [ "$SEARCH_TYPE" = "d" ] && echo "Directories" || echo "All")"
    [ ! -z "$SEARCH_NAME" ] && echo -e "${CYAN}Name Pattern:${NC}     $SEARCH_NAME $([ "$CASE_SENSITIVE" = true ] && echo "(case-sensitive)" || echo "(case-insensitive)")"
    [ ! -z "$SEARCH_SIZE" ] && echo -e "${CYAN}Minimum Size:${NC}     ${SEARCH_SIZE}MB"
    [ ! -z "$SEARCH_DAYS" ] && echo -e "${CYAN}Modified Within:${NC}  Last ${SEARCH_DAYS} days"
    
    echo -e "\n${YELLOW}Searching...${NC}\n"
    
    # Build and execute find command
    local find_cmd=$(build_find_command)
    local results=()
    local count=0
    
    # Execute find and store results
    while IFS= read -r file; do
        if [ -e "$file" ]; then
            results+=("$file")
            ((count++))
        fi
    done < <(eval "$find_cmd" 2>/dev/null)
    
    if [ $count -eq 0 ]; then
        echo -e "${YELLOW}No files found matching the criteria.${NC}\n"
        return 1
    fi
    
    echo -e "${GREEN}Found $count result(s)${NC}\n"
    
    # Display results
    display_results "${results[@]}"
    
    # Offer actions
    offer_actions "${results[@]}"
}

# Function to display results
display_results() {
    local files=("$@")
    
    echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo -e "${MAGENTA}📋 Search Results${NC}"
    echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}\n"
    
    local total_size=0
    
    for i in "${!files[@]}"; do
        local file="${files[$i]}"
        local num=$((i + 1))
        
        if [ -f "$file" ]; then
            local size=$(stat -c %s "$file" 2>/dev/null || stat -f %z "$file" 2>/dev/null)
            local human_size=$(bytes_to_human $size)
            local mod_time=$(stat -c %Y "$file" 2>/dev/null || stat -f %m "$file" 2>/dev/null)
            local formatted_date=$(format_date $mod_time)
            local age_days=$(get_file_age_days "$file")
            
            total_size=$((total_size + size))
            
            echo -e "${GREEN}[$num]${NC} ${CYAN}File:${NC} $(basename "$file")"
            echo -e "     ${BLUE}Path:${NC}     $file"
            echo -e "     ${BLUE}Size:${NC}     $human_size"
            echo -e "     ${BLUE}Modified:${NC} $formatted_date (${age_days} days ago)"
            echo ""
        elif [ -d "$file" ]; then
            local size=$(du -sb "$file" 2>/dev/null | cut -f1)
            local human_size=$(bytes_to_human $size)
            
            echo -e "${GREEN}[$num]${NC} ${CYAN}Directory:${NC} $(basename "$file")"
            echo -e "     ${BLUE}Path:${NC}     $file"
            echo -e "     ${BLUE}Size:${NC}     $human_size"
            echo -e "     ${BLUE}Items:${NC}    $(find "$file" -maxdepth 1 | wc -l) items"
            echo ""
        fi
    done
    
    if [ $total_size -gt 0 ]; then
        echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
        echo -e "${CYAN}Total Size: ${YELLOW}$(bytes_to_human $total_size)${NC}\n"
    fi
}

# Function to offer actions on results
offer_actions() {
    local files=("$@")
    
    echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo -e "${MAGENTA}⚡ Available Actions${NC}"
    echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}\n"
    
    echo -e "${CYAN}What would you like to do with these files?${NC}"
    echo -e "  ${GREEN}1)${NC} Copy to directory"
    echo -e "  ${GREEN}2)${NC} Move to directory"
    echo -e "  ${GREEN}3)${NC} Delete files (with confirmation)"
    echo -e "  ${GREEN}4)${NC} Compress to archive"
    echo -e "  ${GREEN}5)${NC} View file details"
    echo -e "  ${GREEN}6)${NC} Save list to file"
    echo -e "  ${GREEN}7)${NC} Exit"
    echo ""
    
    read -p "Enter your choice (1-7): " action
    
    case $action in
        1) copy_files "${files[@]}" ;;
        2) move_files "${files[@]}" ;;
        3) delete_files "${files[@]}" ;;
        4) compress_files "${files[@]}" ;;
        5) view_file_details "${files[@]}" ;;
        6) save_to_file "${files[@]}" ;;
        7) echo -e "${GREEN}Exiting...${NC}\n"; exit 0 ;;
        *) echo -e "${RED}Invalid choice${NC}\n" ;;
    esac
}

# Function to copy files
copy_files() {
    local files=("$@")
    
    echo -e "\n${CYAN}Enter destination directory:${NC}"
    read -p "> " dest_dir
    
    if [ ! -d "$dest_dir" ]; then
        read -p "Directory doesn't exist. Create it? (yes/no): " create
        if [ "$create" = "yes" ]; then
            mkdir -p "$dest_dir"
            echo -e "${GREEN}✓ Directory created${NC}"
        else
            echo -e "${YELLOW}Operation cancelled${NC}\n"
            return
        fi
    fi
    
    echo -e "\n${YELLOW}Copying files...${NC}"
    local success=0
    local failed=0
    
    for file in "${files[@]}"; do
        if cp -r "$file" "$dest_dir/" 2>/dev/null; then
            echo -e "${GREEN}✓${NC} Copied: $(basename "$file")"
            ((success++))
        else
            echo -e "${RED}✗${NC} Failed: $(basename "$file")"
            ((failed++))
        fi
    done
    
    echo -e "\n${GREEN}Copied: $success${NC} | ${RED}Failed: $failed${NC}\n"
}

# Function to move files
move_files() {
    local files=("$@")
    
    echo -e "\n${CYAN}Enter destination directory:${NC}"
    read -p "> " dest_dir
    
    if [ ! -d "$dest_dir" ]; then
        read -p "Directory doesn't exist. Create it? (yes/no): " create
        if [ "$create" = "yes" ]; then
            mkdir -p "$dest_dir"
            echo -e "${GREEN}✓ Directory created${NC}"
        else
            echo -e "${YELLOW}Operation cancelled${NC}\n"
            return
        fi
    fi
    
    echo -e "\n${YELLOW}Moving files...${NC}"
    local success=0
    local failed=0
    
    for file in "${files[@]}"; do
        if mv "$file" "$dest_dir/" 2>/dev/null; then
            echo -e "${GREEN}✓${NC} Moved: $(basename "$file")"
            ((success++))
        else
            echo -e "${RED}✗${NC} Failed: $(basename "$file")"
            ((failed++))
        fi
    done
    
    echo -e "\n${GREEN}Moved: $success${NC} | ${RED}Failed: $failed${NC}\n"
}

# Function to delete files
delete_files() {
    local files=("$@")
    
    echo -e "\n${RED}⚠️  WARNING: This will permanently delete ${#files[@]} file(s)!${NC}"
    read -p "Type 'DELETE' to confirm: " confirm
    
    if [ "$confirm" != "DELETE" ]; then
        echo -e "${YELLOW}Deletion cancelled${NC}\n"
        return
    fi
    
    echo -e "\n${YELLOW}Deleting files...${NC}"
    local success=0
    local failed=0
    
    for file in "${files[@]}"; do
        if rm -rf "$file" 2>/dev/null; then
            echo -e "${GREEN}✓${NC} Deleted: $(basename "$file")"
            ((success++))
        else
            echo -e "${RED}✗${NC} Failed: $(basename "$file")"
            ((failed++))
        fi
    done
    
    echo -e "\n${GREEN}Deleted: $success${NC} | ${RED}Failed: $failed${NC}\n"
}

# Function to compress files
compress_files() {
    local files=("$@")
    local timestamp=$(date +%Y%m%d_%H%M%S)
    local archive_name="search_results_${timestamp}.tar.gz"
    
    echo -e "\n${CYAN}Creating archive: ${archive_name}${NC}"
    
    # Create temporary file list
    local temp_list=$(mktemp)
    printf '%s\n' "${files[@]}" > "$temp_list"
    
    if tar -czf "$archive_name" -T "$temp_list" 2>/dev/null; then
        local archive_size=$(du -h "$archive_name" | cut -f1)
        echo -e "${GREEN}✓ Archive created successfully${NC}"
        echo -e "${CYAN}Archive:${NC} $archive_name"
        echo -e "${CYAN}Size:${NC}    $archive_size"
        echo -e "${CYAN}Files:${NC}   ${#files[@]}"
    else
        echo -e "${RED}✗ Failed to create archive${NC}"
    fi
    
    rm -f "$temp_list"
    echo ""
}

# Function to view detailed file info
view_file_details() {
    local files=("$@")
    
    echo -e "\n${CYAN}Enter file number to view details (or 'q' to quit):${NC}"
    read -p "> " choice
    
    if [ "$choice" = "q" ]; then
        return
    fi
    
    local index=$((choice - 1))
    
    if [ $index -ge 0 ] && [ $index -lt ${#files[@]} ]; then
        local file="${files[$index]}"
        
        echo -e "\n${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
        echo -e "${MAGENTA}📄 Detailed File Information${NC}"
        echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}\n"
        
        ls -lh "$file"
        
        if [ -f "$file" ]; then
            echo -e "\n${CYAN}File Type:${NC}"
            file "$file"
            
            echo -e "\n${CYAN}Permissions:${NC}"
            stat "$file" 2>/dev/null || stat -x "$file" 2>/dev/null
        fi
        
        echo ""
    else
        echo -e "${RED}Invalid file number${NC}\n"
    fi
}

# Function to save results to file
save_to_file() {
    local files=("$@")
    local output_file="search_results_$(date +%Y%m%d_%H%M%S).txt"
    
    {
        echo "File Search Results"
        echo "Generated: $(date)"
        echo "Search Path: $SEARCH_PATH"
        [ ! -z "$SEARCH_NAME" ] && echo "Name Pattern: $SEARCH_NAME"
        [ ! -z "$SEARCH_SIZE" ] && echo "Min Size: ${SEARCH_SIZE}MB"
        [ ! -z "$SEARCH_DAYS" ] && echo "Modified: Last ${SEARCH_DAYS} days"
        echo ""
        echo "Results:"
        echo "----------------------------------------"
        printf '%s\n' "${files[@]}"
    } > "$output_file"
    
    echo -e "\n${GREEN}✓ Results saved to: ${CYAN}$output_file${NC}\n"
}

# Main script execution
main() {
    # Parse command line arguments
    if [ $# -eq 0 ]; then
        print_header
        print_usage
        exit 0
    fi
    
    while getopts "n:s:d:p:t:ihv" opt; do
        case $opt in
            n) SEARCH_NAME="$OPTARG" ;;
            s) SEARCH_SIZE="$OPTARG" ;;
            d) SEARCH_DAYS="$OPTARG" ;;
            p) SEARCH_PATH="$OPTARG" ;;
            t) SEARCH_TYPE="$OPTARG" ;;
            i) CASE_SENSITIVE=false ;;
            h) print_header; print_usage; exit 0 ;;
            v) VERBOSE=true ;;
            \?) echo -e "${RED}Invalid option: -$OPTARG${NC}" >&2; exit 1 ;;
        esac
    done
    
    # Validate search path
    if [ ! -d "$SEARCH_PATH" ]; then
        echo -e "${RED}Error: Search path '$SEARCH_PATH' does not exist${NC}"
        exit 1
    fi
    
    print_header
    search_files
}

# Run the script
main "$@"
