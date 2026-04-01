#!/bin/bash

# Check if a directory was provided
TARGET_DIR=${1:-"."}

# Convert TARGET_DIR to an absolute path for reliability
TARGET_DIR=$(realpath "$TARGET_DIR")

if [ ! -d "$TARGET_DIR" ]; then
    echo "Error: Directory $TARGET_DIR does not exist."
    exit 1
fi

echo "Processing folder: $TARGET_DIR"

# 1. Extract the range of indices (i for rows, j for columns)
# Specifically looking for snap_SIM_i_j.png
indices_i=$(ls "$TARGET_DIR"/snap_SIM_*_*.png 2>/dev/null | sed -E 's/.*snap_SIM_([0-9]+)_[0-9]+.png/\1/' | sort -nu)
indices_j=$(ls "$TARGET_DIR"/snap_SIM_*_*.png 2>/dev/null | sed -E 's/.*snap_SIM_[0-9]+_([0-9]+).png/\1/' | sort -nu)

if [ -z "$indices_i" ]; then
    echo "Error: No files matching 'snap_SIM_i_j.png' found in $TARGET_DIR"
    exit 1
fi

# Find min and max
min_i=$(echo "$indices_i" | head -n 1)
max_i=$(echo "$indices_i" | tail -n 1)
min_j=$(echo "$indices_j" | head -n 1)
max_j=$(echo "$indices_j" | tail -n 1)

# Calculate counts
num_rows=$((max_i - min_i + 1))
num_cols=$((max_j - min_j + 1))

echo "Detected Grid: $num_rows rows (i=$min_i to $max_i) x $num_cols columns (j=$min_j to $max_j)"

# 2. Create a temporary folder for placeholders
TMP_DIR=$(mktemp -d)

# 3. Create a blank/transparent placeholder for missing files
# Uses the first available image as a size template
REF_IMG=$(ls "$TARGET_DIR"/snap_SIM_*_*.png | head -n 1)
convert "$REF_IMG" -alpha transparent "$TMP_DIR/placeholder.png"

# 4. Build the file list in the correct order
# To invert Y-axis: i goes from max down to min
FILE_LIST=""
for (( i=$max_i; i>=$min_i; i-- )); do
    for (( j=$min_j; j<=$max_j; j++ )); do
        FILE="$TARGET_DIR/snap_SIM_${i}_${j}.png"
        
        if [ -f "$FILE" ]; then
            FILE_LIST="$FILE_LIST $FILE"
        else
            # If file is missing, use the placeholder
            FILE_LIST="$FILE_LIST $TMP_DIR/placeholder.png"
            echo "Notice: Missing index ${i}_${j}, inserting placeholder."
        fi
    done
done

# 5. Run Montage and save to TARGET_DIR
OUTPUT_NAME="composite_grid_${num_cols}x${num_rows}.png"
OUTPUT_PATH="$TARGET_DIR/$OUTPUT_NAME"

echo "Creating composite image..."

# Added -limit flags to prevent "cache resources exhausted" 
# and added logic to check if the command actually worked.
# Inside your snapshot_grid.sh, replace the montage command block:
if montage -limit memory 4GiB -limit map 8GiB -limit area 1GiB -limit disk 16GiB \
           -tile "${num_cols}x${num_rows}" \
           -geometry 800x800+2+2 $FILE_LIST "$OUTPUT_PATH"; then
    echo "Success! Grid saved to: $OUTPUT_PATH"
else
    echo "Error: ImageMagick failed to create the composite image."
    rm -rf "$TMP_DIR"
    exit 1
fi

# Cleanup
rm -rf "$TMP_DIR"