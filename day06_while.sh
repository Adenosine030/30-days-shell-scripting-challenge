#!/bin/bash
#
# Day 6: While Loops - Guessing Game
# Author: CloudDemigod (Adenosine030)
# Date: 2025-11-11
# Purpose: Number guessing game using while loop
#

# Colors
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

# Generate random number between 1 and 10
SECRET_NUMBER=$((RANDOM % 10 + 1))

# Initialize attempts counter
ATTEMPTS=0

echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${BLUE}   Number Guessing Game${NC}"
echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo ""
echo -e "${YELLOW}I'm thinking of a number between 1 and 10...${NC}"
echo ""

# While loop - continues until correct guess
while true; do
    # Get user guess
    echo -n "Enter your guess: "
    read GUESS
    
    # Increment attempts
    ATTEMPTS=$((ATTEMPTS + 1))
    
    # Validate input
    if ! [[ "$GUESS" =~ ^[0-9]+$ ]]; then
        echo -e "${RED}❌ Please enter a valid number!${NC}"
        echo ""
        continue
    fi
    
    # Check if guess is correct
    if [ "$GUESS" -eq "$SECRET_NUMBER" ]; then
        echo ""
        echo -e "${GREEN}🎉 Congratulations! You guessed it!${NC}"
        echo -e "${GREEN}The number was: $SECRET_NUMBER${NC}"
        echo -e "${GREEN}You got it in $ATTEMPTS attempt(s)!${NC}"
        echo ""
        
        # Rate performance
        if [ $ATTEMPTS -eq 1 ]; then
            echo -e "${YELLOW}⭐⭐⭐ AMAZING! First try!${NC}"
        elif [ $ATTEMPTS -le 3 ]; then
            echo -e "${YELLOW}⭐⭐ Great job!${NC}"
        else
            echo -e "${YELLOW}⭐ You did it!${NC}"
        fi
        
        break
    elif [ "$GUESS" -lt "$SECRET_NUMBER" ]; then
        echo -e "${YELLOW}📈 Too low! Try a higher number.${NC}"
    else
        echo -e "${YELLOW}📉 Too high! Try a lower number.${NC}"
    fi
    
    echo ""
done

echo ""
echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${BLUE}   Thanks for playing!${NC}"
echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
