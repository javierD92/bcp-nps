#!/bin/bash

# Check if a filename was provided
if [ -z "$1" ]; then
    echo "Usage: $0 <filename>"
    exit 1
fi

TARGET_FILE=$1

# 1. Create a backup just in case
cp "$TARGET_FILE" "${TARGET_FILE}.bak"

# 2. Use sed to delete any line containing a NULL byte (\x00)
# The -i flag edits the file in-place
sed -i '/\x00/d' "$TARGET_FILE"

echo "Done! Cleaned $TARGET_FILE. Original saved as ${TARGET_FILE}.bak"
