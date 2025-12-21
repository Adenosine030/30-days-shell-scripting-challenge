#!/bin/bash
# Day 26: Advanced Text Processing

CSV_FILE="data.csv"

if [[ ! -f "$CSV_FILE" ]]; then
    echo "ERROR: CSV file not found."
    exit 1
fi

echo "Employees in IT Department:"
echo "----------------------------"

# -----------------------------
# 1–3. Extract + Filter
# -----------------------------
awk -F',' 'NR>1 && $2=="IT" {print $1, $3}' "$CSV_FILE"

echo
echo "Salary Statistics (IT Department)"
echo "--------------------------------"

# -----------------------------
# 4. Calculate sum & average
# -----------------------------
awk -F',' '
NR>1 && $2=="IT" {
    sum+=$3
    count++
}
END {
    if (count > 0) {
        printf "Total Salary: %d\n", sum
        printf "Average Salary: %.2f\n", sum/count
    } else {
        print "No matching records found."
    }
}' "$CSV_FILE"

# -----------------------------
# 5. Formatted report done
# -----------------------------
