#!/bin/bash
#
# Day 5: For Loops
# Author: CloudDemigod (Adenosine030)
# Date: 2025-11-11
# Purpose: Loop through files and display information
#

# Colors
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${BLUE}   Text Files Information${NC}"
echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo ""

# Initialize counter
COUNT=0

# Check if any .txt files exist
if ! ls *.txt &> /dev/null; then
    echo -e "${YELLOW}No .txt files found in current directory${NC}"
    exit 0
fi

# Loop through all .txt files
for FILE in *.txt; do
    # Increment counter
    COUNT=$((COUNT + 1))
    
    # Get file information
    SIZE=$(stat -c %s "$FILE" 2>/dev/null || stat -f %z "$FILE" 2>/dev/null)
    MODIFIED=$(stat -c %y "$FILE" 2>/dev/null | cut -d' ' -f1 || stat -f %Sm "$FILE" 2>/dev/null)
    
    # Display file info
    echo -e "${GREEN}File #$COUNT:${NC}"
    echo "  📄 Name: $FILE"
    echo "  📊 Size: $SIZE bytes"
    echo "  📅 Modified: $MODIFIED"
    echo ""
done

# Display summary
echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${GREEN}Total files found: $COUNT${NC}"
echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
