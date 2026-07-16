#!/bin/bash
# Validate GEO submission folder before upload
# Usage: ./validate_submission.sh /path/to/submission/folder
#
# Checks for common issues that cause GEO rejections:
# - ZIP files (not accepted)
# - Files over 100GB
# - Invalid filenames (spaces, special characters)
# - Missing gzip compression
# - Uncompressed large files

set -e

FOLDER="${1:-.}"
ERRORS=0
WARNINGS=0

RED='\033[0;31m'
YELLOW='\033[1;33m'
GREEN='\033[0;32m'
NC='\033[0m' # No Color

error() {
    echo -e "${RED}ERROR:${NC} $1"
    ((ERRORS++))
}

warning() {
    echo -e "${YELLOW}WARNING:${NC} $1"
    ((WARNINGS++))
}

success() {
    echo -e "${GREEN}OK:${NC} $1"
}

if [ ! -d "$FOLDER" ]; then
    echo "Error: Directory '$FOLDER' does not exist"
    exit 1
fi

echo "=========================================="
echo "GEO Submission Validation"
echo "Folder: $FOLDER"
echo "=========================================="
echo ""

# Check for ZIP files (not accepted by GEO)
echo "Checking for ZIP files..."
ZIP_FILES=$(find "$FOLDER" -type f -name "*.zip" 2>/dev/null || true)
if [ -n "$ZIP_FILES" ]; then
    error "ZIP files detected (not accepted by GEO):"
    echo "$ZIP_FILES" | while read -r f; do echo "  - $f"; done
    echo "  Solution: Decompress and re-compress with gzip (.gz)"
else
    success "No ZIP files found"
fi
echo ""

# Check for RAR files
echo "Checking for RAR files..."
RAR_FILES=$(find "$FOLDER" -type f -name "*.rar" 2>/dev/null || true)
if [ -n "$RAR_FILES" ]; then
    error "RAR files detected (not accepted by GEO):"
    echo "$RAR_FILES" | while read -r f; do echo "  - $f"; done
else
    success "No RAR files found"
fi
echo ""

# Check for files over 100GB
echo "Checking file sizes (max 100GB)..."
LARGE_FILES=$(find "$FOLDER" -type f -size +100G 2>/dev/null || true)
if [ -n "$LARGE_FILES" ]; then
    error "Files over 100GB detected:"
    echo "$LARGE_FILES" | while read -r f; do
        SIZE=$(du -h "$f" | cut -f1)
        echo "  - $f ($SIZE)"
    done
    echo "  Solution: Split files or contact GEO for guidance"
else
    success "All files under 100GB"
fi
echo ""

# Check for spaces in filenames
echo "Checking for spaces in filenames..."
SPACE_FILES=$(find "$FOLDER" -type f -name "* *" 2>/dev/null || true)
if [ -n "$SPACE_FILES" ]; then
    error "Filenames with spaces detected:"
    echo "$SPACE_FILES" | while read -r f; do echo "  - $f"; done
    echo "  Solution: Rename files to use underscores or hyphens"
else
    success "No spaces in filenames"
fi
echo ""

# Check for special characters in filenames
echo "Checking for special characters in filenames..."
SPECIAL_FILES=$(find "$FOLDER" -type f -name "*[()@#\$%^&\!]*" 2>/dev/null || true)
if [ -n "$SPECIAL_FILES" ]; then
    error "Filenames with special characters detected:"
    echo "$SPECIAL_FILES" | while read -r f; do echo "  - $f"; done
    echo "  Solution: Use only alphanumeric characters, hyphens, and underscores"
else
    success "No special characters in filenames"
fi
echo ""

# Check for uncompressed FASTQ files
echo "Checking for uncompressed FASTQ files..."
UNCOMPRESSED_FASTQ=$(find "$FOLDER" -type f \( -name "*.fastq" -o -name "*.fq" \) ! -name "*.gz" 2>/dev/null || true)
if [ -n "$UNCOMPRESSED_FASTQ" ]; then
    warning "Uncompressed FASTQ files detected:"
    echo "$UNCOMPRESSED_FASTQ" | while read -r f; do echo "  - $f"; done
    echo "  Solution: Compress with gzip: gzip filename.fastq"
else
    success "All FASTQ files are compressed"
fi
echo ""

# Check for uncompressed large CSV/TSV files (>10MB)
echo "Checking for large uncompressed text files..."
LARGE_TEXT=$(find "$FOLDER" -type f \( -name "*.csv" -o -name "*.tsv" -o -name "*.txt" \) ! -name "*.gz" -size +10M 2>/dev/null || true)
if [ -n "$LARGE_TEXT" ]; then
    warning "Large uncompressed text files (>10MB):"
    echo "$LARGE_TEXT" | while read -r f; do
        SIZE=$(du -h "$f" | cut -f1)
        echo "  - $f ($SIZE)"
    done
    echo "  Recommendation: Compress with gzip for faster upload"
else
    success "No large uncompressed text files"
fi
echo ""

# Check for FASTQ.gz files and verify gzip integrity
echo "Verifying gzip file integrity (sampling up to 5 files)..."
GZ_FILES=$(find "$FOLDER" -type f -name "*.gz" 2>/dev/null | head -5)
GZ_VALID=true
if [ -n "$GZ_FILES" ]; then
    echo "$GZ_FILES" | while read -r f; do
        if ! gzip -t "$f" 2>/dev/null; then
            error "Corrupted gzip file: $f"
            GZ_VALID=false
        fi
    done
    if [ "$GZ_VALID" = true ]; then
        success "Sampled gzip files are valid"
    fi
else
    echo "  No .gz files to verify"
fi
echo ""

# Summary
echo "=========================================="
echo "Validation Summary"
echo "=========================================="
if [ $ERRORS -gt 0 ]; then
    echo -e "${RED}ERRORS: $ERRORS${NC} (must fix before submission)"
fi
if [ $WARNINGS -gt 0 ]; then
    echo -e "${YELLOW}WARNINGS: $WARNINGS${NC} (recommended to fix)"
fi
if [ $ERRORS -eq 0 ] && [ $WARNINGS -eq 0 ]; then
    echo -e "${GREEN}All checks passed!${NC}"
fi
echo ""

# Exit with error code if errors found
if [ $ERRORS -gt 0 ]; then
    exit 1
fi
