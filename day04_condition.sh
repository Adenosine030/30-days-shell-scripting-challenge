#!/bin/bash
echo "Input any number"
read NUMBER
if [ -z "$NUMBER" ]; then
    echo "❌ Error: No input provided!"
    exit 1
fi

# Check if input is a valid number
if ! [[ "$NUMBER" =~ ^-?[0-9]+$ ]]; then
    echo "❌ Error: '$NUMBER' is not a valid number!"
    exit 1
fi

# Check if number is positive, negative, or zero
if [ "$NUMBER" -gt 0 ]; then
    echo "✅ $NUMBER is POSITIVE"
elif [ "$NUMBER" -lt 0 ]; then
    echo "✅ $NUMBER is NEGATIVE"
else
    echo "✅ $NUMBER is ZERO"
fi

# Check if number is even or odd
if [ $((NUMBER % 2)) -eq 0 ]; then
    echo "✅ $NUMBER is EVEN"
else
    echo "✅ $NUMBER is ODD"
fi
