#!/bin/bash
if [ $# -ne 1 ]; then
	echo "* usage: $0 <filename>"
	exit 1
fi
FILE=$1
if [ -f "$FILE" ]; then
	echo "Yes, File Found: $FILE"
	FILE_SIZE=$(stat -c %s "$FILE")
	LINE_COUNT=$(wc -l < "$FILE")

	echo "File Size; $FILE_SIZE bytes"
	echo "Line Count; $LINE_COUNT"
else 
	echo "File not found: $FILE"
	exit 1
fi
