#!/bin/bash
# Generate MD5 checksums for GEO submission files
# Usage: ./generate_md5.sh /path/to/submission/folder
#
# Generates checksums for all .gz, .csv, .tsv, .h5, and .rds files
# Output is formatted for easy copy-paste into GEO metadata spreadsheet

set -e

FOLDER="${1:-.}"
OUTPUT_FILE="${FOLDER}/md5_checksums.txt"

if [ ! -d "$FOLDER" ]; then
    echo "Error: Directory '$FOLDER' does not exist"
    exit 1
fi

echo "Generating MD5 checksums for files in: $FOLDER"
echo ""

# Detect OS for correct md5 command
if [[ "$OSTYPE" == "darwin"* ]]; then
    # macOS
    MD5_CMD="md5 -r"
else
    # Linux
    MD5_CMD="md5sum"
fi

# Find and checksum files
{
    echo "# MD5 Checksums for GEO Submission"
    echo "# Generated: $(date)"
    echo "# Format: checksum  filename"
    echo ""

    find "$FOLDER" -type f \( \
        -name "*.gz" -o \
        -name "*.fastq.gz" -o \
        -name "*.csv" -o \
        -name "*.tsv" -o \
        -name "*.txt" -o \
        -name "*.h5" -o \
        -name "*.hdf5" -o \
        -name "*.rds" -o \
        -name "*.mtx" \
    \) ! -name "md5_checksums.txt" -exec $MD5_CMD {} \; 2>/dev/null | sort -k2
} > "$OUTPUT_FILE"

# Count files processed
FILE_COUNT=$(grep -v "^#" "$OUTPUT_FILE" | grep -v "^$" | wc -l | tr -d ' ')

echo "Checksums saved to: $OUTPUT_FILE"
echo "Total files processed: $FILE_COUNT"
echo ""
echo "Copy the checksums to the 'file checksum' column in your metadata spreadsheet."
