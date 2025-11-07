#!/bin/bash
echo "What is your name? "
read NAME
echo "Hello, $NAME! what is your age?"
read AGE
echo "Hey $NAME, you are $AGE years old."
CURRENT_YEAR=$(date +%Y)
BIRTH_YEAR=$((CURRENT_YEAR - AGE))
echo "------------------"
echo "SUMMARY"
echo "Name: $NAME"
echo "Age: $AGE"
echo "You were born around $BIRTH_YEAR"
echo "-------------------"
date
