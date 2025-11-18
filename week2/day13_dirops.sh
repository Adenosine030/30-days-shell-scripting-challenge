#!/bin/bash
#
# Day 13: Directory Navigator & Manager
# Author: Ademola Adenigba (CloudDemigod)
# Date: November 18, 2025
#
# Advanced directory operations for managing project folders
# Lists subdirectories, analyzes sizes, finds largest, and offers compression

# Color codes for output
RED='\033[0;31m'
YELLOW='\033[1;33m'
GREEN='\033[0;32m'
BLUE='\033[0;34m'
MAGENTA='\033[0;35m'
CYAN='\033[0;36m'
BOLD='\033[1m'
NC='\033[0m' # No Color

# Default target directory
TARGET_DIR="${1:-.}"

# Function to print header
print_header() {
    clear
    echo -e "${CYAN}╔═══════════════════════════════════════════════════════════════╗${NC}"
    echo -e "${CYAN}║           DIRECTORY NAVIGATOR & MANAGER                       ║${NC}"
    echo -e "${CYAN}║              Smart Folder Analysis Tool                       ║${NC}"
    echo -e "${CYAN}╔═══════════════════════════════════════════════════════════════╗${NC}"
    echo -e "${BLUE}Target Directory: ${CYAN}$(realpath "$TARGET_DIR")${NC}\n"
}

# Function to convert bytes to human-readable format
bytes_to_human() {
    local bytes=$1
    local sizes=("B" "KB" "MB" "GB" "TB")
    local size_index=0
    local size=$bytes
    
    while (( $(echo "$size > 1024" | bc -l) )) && [ $size_index -lt 4 ]; do
        size=$(echo "scale=2; $size / 1024" | bc)
        ((size_index++))
    done
    
    printf "%.2f %s" "$size" "${sizes[$size_index]}"
}

# Function to draw progress bar
draw_bar() {
    local percentage=$1
    local width=30
    local filled=$((percentage * width / 100))
    local empty=$((width - filled))
    
    # Color based on percentage
    local color=$GREEN
    if [ $percentage -ge 80 ]; then
        color=$RED
    elif [ $percentage -ge 60 ]; then
        color=$YELLOW
    fi
    
    echo -ne "${color}["
    printf '%*s' $filled | tr ' ' '█'
    printf '%*s' $empty | tr ' ' '░'
    echo -ne "]${NC}"
}

# Function to validate directory
validate_directory() {
    if [ ! -d "$TARGET_DIR" ]; then
        echo -e "${RED}Error: '$TARGET_DIR' is not a valid directory!${NC}"
        exit 1
    fi
    
    if [ ! -r "$TARGET_DIR" ]; then
        echo -e "${RED}Error: No read permission for '$TARGET_DIR'${NC}"
        exit 1
    fi
}

# Function to list all subdirectories with sizes
list_subdirectories() {
    echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo -e "${MAGENTA}📂 Subdirectories Analysis${NC}"
    echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}\n"
    
    # Array to store directory info
    declare -a dir_names
    declare -a dir_sizes
    local total_size=0
    local dir_count=0
    
    echo -e "${CYAN}Scanning directories...${NC}\n"
    
    # Get subdirectories and their sizes
    while IFS= read -r dir; do
        if [ -d "$dir" ]; then
            dir_name=$(basename "$dir")
            
            # Calculate directory size (in bytes)
            dir_size=$(du -sb "$dir" 2>/dev/null | cut -f1)
            
            # Skip if size is 0 or couldn't be calculated
            if [ -z "$dir_size" ] || [ "$dir_size" -eq 0 ]; then
                continue
            fi
            
            dir_names+=("$dir_name")
            dir_sizes+=("$dir_size")
            total_size=$((total_size + dir_size))
            ((dir_count++))
        fi
    done < <(find "$TARGET_DIR" -maxdepth 1 -mindepth 1 -type d 2>/dev/null | sort)
    
    if [ $dir_count -eq 0 ]; then
        echo -e "${YELLOW}No subdirectories found in '$TARGET_DIR'${NC}\n"
        return 1
    fi
    
    # Display header
    echo -e "${CYAN}${BOLD}Directory Name${NC}                    ${CYAN}${BOLD}Size${NC}           ${CYAN}${BOLD}% of Total${NC}    ${CYAN}${BOLD}Visual${NC}"
    echo -e "${BLUE}────────────────────────────────────────────────────────────────────────────${NC}"
    
    # Display each directory
    for i in "${!dir_names[@]}"; do
        local name="${dir_names[$i]}"
        local size="${dir_sizes[$i]}"
        local percentage=0
        
        if [ $total_size -gt 0 ]; then
            percentage=$((size * 100 / total_size))
        fi
        
        local human_size=$(bytes_to_human $size)
        
        # Color code based on size
        local name_color=$GREEN
        if [ $percentage -ge 30 ]; then
            name_color=$RED
        elif [ $percentage -ge 15 ]; then
            name_color=$YELLOW
        fi
        
        printf "${name_color}%-30s${NC} %-15s %3d%%    " "$name" "$human_size" "$percentage"
        draw_bar $percentage
        echo ""
    done
    
    echo -e "${BLUE}────────────────────────────────────────────────────────────────────────────${NC}"
    echo -e "${CYAN}Total Directories: ${YELLOW}$dir_count${NC}"
    echo -e "${CYAN}Total Size:        ${YELLOW}$(bytes_to_human $total_size)${NC}\n"
    
    # Return arrays for use by other functions
    export LARGEST_DIR_NAME="${dir_names[0]}"
    export LARGEST_DIR_SIZE="${dir_sizes[0]}"
    
    # Find largest directory
    for i in "${!dir_sizes[@]}"; do
        if [ "${dir_sizes[$i]}" -gt "$LARGEST_DIR_SIZE" ]; then
            LARGEST_DIR_NAME="${dir_names[$i]}"
            LARGEST_DIR_SIZE="${dir_sizes[$i]}"
        fi
    done
}

# Function to find and display largest directory
find_largest_directory() {
    echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo -e "${MAGENTA}🏆 Largest Subdirectory${NC}"
    echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}\n"
    
    if [ -z "$LARGEST_DIR_NAME" ]; then
        echo -e "${YELLOW}No directories to analyze${NC}\n"
        return 1
    fi
    
    local largest_path="$TARGET_DIR/$LARGEST_DIR_NAME"
    local human_size=$(bytes_to_human $LARGEST_DIR_SIZE)
    
    echo -e "${CYAN}Directory:${NC}  ${GREEN}$LARGEST_DIR_NAME${NC}"
    echo -e "${CYAN}Full Path:${NC}  ${BLUE}$largest_path${NC}"
    echo -e "${CYAN}Size:${NC}       ${YELLOW}$human_size${NC}"
    echo -e "${CYAN}Files:${NC}      ${YELLOW}$(find "$largest_path" -type f 2>/dev/null | wc -l)${NC}"
    echo -e "${CYAN}Subdirs:${NC}    ${YELLOW}$(find "$largest_path" -type d 2>/dev/null | wc -l)${NC}"
    
    # Show top 5 largest files in the directory
    echo -e "\n${CYAN}Top 5 Largest Files:${NC}"
    echo -e "${BLUE}────────────────────────────────────────────────────────────${NC}"
    
    find "$largest_path" -type f -exec du -h {} + 2>/dev/null | \
    sort -rh | head -5 | while read size file; do
        filename=$(basename "$file")
        printf "  %-15s %s\n" "$size" "$filename"
    done
    
    echo ""
}

# Function to offer compression
offer_compression() {
    echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo -e "${MAGENTA}📦 Compression Options${NC}"
    echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}\n"
    
    if [ -z "$LARGEST_DIR_NAME" ]; then
        echo -e "${YELLOW}No directory to compress${NC}\n"
        return 1
    fi
    
    local largest_path="$TARGET_DIR/$LARGEST_DIR_NAME"
    local human_size=$(bytes_to_human $LARGEST_DIR_SIZE)
    
    echo -e "${YELLOW}The largest directory is: ${GREEN}$LARGEST_DIR_NAME${YELLOW} ($human_size)${NC}"
    echo -e "${YELLOW}Compressing it could save disk space.${NC}\n"
    
    echo -e "${CYAN}Would you like to compress this directory?${NC}"
    echo -e "  ${GREEN}1)${NC} tar.gz (Good compression, widely compatible)"
    echo -e "  ${GREEN}2)${NC} zip (Best compatibility, moderate compression)"
    echo -e "  ${GREEN}3)${NC} tar.bz2 (Best compression, slower)"
    echo -e "  ${GREEN}4)${NC} Skip compression"
    echo ""
    
    read -p "Enter your choice (1-4): " choice
    
    case $choice in
        1)
            compress_directory "tar.gz" "$largest_path"
            ;;
        2)
            compress_directory "zip" "$largest_path"
            ;;
        3)
            compress_directory "tar.bz2" "$largest_path"
            ;;
        4)
            echo -e "${YELLOW}Compression skipped${NC}\n"
            ;;
        *)
            echo -e "${RED}Invalid choice. Compression skipped.${NC}\n"
            ;;
    esac
}

# Function to compress directory
compress_directory() {
    local format=$1
    local dir_path=$2
    local dir_name=$(basename "$dir_path")
    local timestamp=$(date +%Y%m%d_%H%M%S)
    local output_file=""
    
    echo -e "\n${CYAN}Starting compression...${NC}\n"
    
    case $format in
        "tar.gz")
            output_file="${dir_name}_${timestamp}.tar.gz"
            echo -e "${BLUE}Creating: ${output_file}${NC}"
            tar -czf "$output_file" -C "$TARGET_DIR" "$dir_name" 2>/dev/null
            ;;
        "zip")
            output_file="${dir_name}_${timestamp}.zip"
            echo -e "${BLUE}Creating: ${output_file}${NC}"
            zip -rq "$output_file" "$dir_path" 2>/dev/null
            ;;
        "tar.bz2")
            output_file="${dir_name}_${timestamp}.tar.bz2"
            echo -e "${BLUE}Creating: ${output_file}${NC}"
            tar -cjf "$output_file" -C "$TARGET_DIR" "$dir_name" 2>/dev/null
            ;;
    esac
    
    if [ -f "$output_file" ]; then
        local archive_size=$(du -h "$output_file" | cut -f1)
        local original_size=$(bytes_to_human $LARGEST_DIR_SIZE)
        local compression_ratio=$(echo "scale=1; (1 - $(stat -f%z "$output_file" 2>/dev/null || stat -c%s "$output_file") / $LARGEST_DIR_SIZE) * 100" | bc)
        
        echo -e "\n${GREEN}✓ Compression successful!${NC}"
        echo -e "${CYAN}Archive File:${NC}      ${output_file}"
        echo -e "${CYAN}Original Size:${NC}     ${original_size}"
        echo -e "${CYAN}Compressed Size:${NC}   ${archive_size}"
        echo -e "${CYAN}Space Saved:${NC}       ${YELLOW}~${compression_ratio}%${NC}"
        echo -e "${CYAN}Location:${NC}          ${BLUE}$(pwd)/$output_file${NC}\n"
        
        # Ask if user wants to delete original
        read -p "Delete original directory? (yes/no): " delete_choice
        if [ "$delete_choice" = "yes" ]; then
            rm -rf "$dir_path"
            echo -e "${GREEN}✓ Original directory deleted${NC}\n"
        else
            echo -e "${YELLOW}Original directory kept${NC}\n"
        fi
    else
        echo -e "${RED}✗ Compression failed!${NC}\n"
    fi
}

# Function to show disk usage summary
show_disk_summary() {
    echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo -e "${MAGENTA}💾 Disk Space Summary${NC}"
    echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}\n"
    
    # Get filesystem info for current directory
    local fs_info=$(df -h "$TARGET_DIR" | tail -1)
    local total=$(echo $fs_info | awk '{print $2}')
    local used=$(echo $fs_info | awk '{print $3}')
    local available=$(echo $fs_info | awk '{print $4}')
    local percentage=$(echo $fs_info | awk '{print $5}' | sed 's/%//')
    
    echo -e "${CYAN}Filesystem:${NC}     $(echo $fs_info | awk '{print $1}')"
    echo -e "${CYAN}Total Space:${NC}    ${total}"
    echo -e "${CYAN}Used:${NC}           ${used}"
    echo -e "${CYAN}Available:${NC}      ${available}"
    echo -ne "${CYAN}Usage:${NC}          "
    draw_bar $percentage
    echo -e " ${YELLOW}${percentage}%${NC}\n"
}

# Function to show file type statistics
show_file_statistics() {
    echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo -e "${MAGENTA}📊 File Type Statistics${NC}"
    echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}\n"
    
    echo -e "${CYAN}Top 10 File Types by Count:${NC}"
    echo -e "${BLUE}────────────────────────────────────────────────────────────${NC}"
    
    find "$TARGET_DIR" -type f 2>/dev/null | \
    sed 's/.*\.//' | sort | uniq -c | sort -rn | head -10 | \
    while read count ext; do
        printf "${GREEN}%-10s${NC} %s files\n" ".$ext" "$count"
    done
    
    echo ""
}

# Main execution
main() {
    print_header
    validate_directory
    
    # Step 1: List all subdirectories with sizes
    list_subdirectories
    
    if [ $? -eq 0 ]; then
        # Step 2: Show largest directory details
        find_largest_directory
        
        # Step 3: Show file statistics
        show_file_statistics
        
        # Step 4: Show disk summary
        show_disk_summary
        
        # Step 5: Offer compression
        offer_compression
    fi
    
    echo -e "${GREEN}✓ Directory analysis complete!${NC}\n"
}

# Run the script
main
