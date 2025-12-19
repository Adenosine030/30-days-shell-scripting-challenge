#!/bin/bash
# Day 25: Parallel Processing
# This script downloads multiple URLs sequentially and in parallel,
# shows progress, and compares execution time.

# -----------------------------
# Validate input
# -----------------------------
if [[ "$#" -lt 1 ]]; then
    echo "Usage: $0 <url1> <url2> <url3> ..."
    exit 1
fi

URLS=("$@")
DOWNLOAD_DIR="./downloads"

mkdir -p "$DOWNLOAD_DIR"

# -----------------------------
# Function: download a single URL
# -----------------------------
download_file() {
    local url="$1"
    local filename
    filename=$(basename "$url")

    echo "Starting download: $filename"
    curl -L --silent --show-error --progress-bar "$url" -o "$DOWNLOAD_DIR/$filename"
    echo "Finished download: $filename"
}

# -----------------------------
# Sequential download
# -----------------------------
echo "=============================="
echo "Starting SEQUENTIAL downloads"
echo "=============================="

start_seq=$(date +%s)

for url in "${URLS[@]}"; do
    download_file "$url"
done

end_seq=$(date +%s)
seq_time=$((end_seq - start_seq))

echo "Sequential download time: ${seq_time}s"
echo

# -----------------------------
# Parallel download
# -----------------------------
echo "=============================="
echo "Starting PARALLEL downloads"
echo "=============================="

start_par=$(date +%s)

for url in "${URLS[@]}"; do
    download_file "$url" &
done

# Wait for all background jobs to finish
wait

end_par=$(date +%s)
par_time=$((end_par - start_par))

echo "Parallel download time: ${par_time}s"
echo

# -----------------------------
# Final Report
# -----------------------------
echo "=============================="
echo "Download Comparison Report"
echo "=============================="
echo "Sequential Time : ${seq_time}s"
echo "Parallel Time   : ${par_time}s"

if [[ "$par_time" -lt "$seq_time" ]]; then
    echo "✅ Parallel processing was faster!"
else
    echo "⚠️ Parallel processing was not faster (network bound)."
fi
