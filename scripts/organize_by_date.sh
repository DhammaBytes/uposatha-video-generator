#!/bin/zsh
#
# Organize Videos by Date
# =======================
# Reads dates.txt and creates dated directories for generated videos.
# Moves videos from _output/ into directories like "2026-01-03".
#
# Usage:
#   ./organize_by_date.sh
#
# Excludes special days:
#   - Ānāpānasati Day
#   - Āsāḷha Pūjā
#   - Visākha Pūjā
#   - Magha Puja
#
# Input:  dates.txt, _output/*.mp4
# Output: dated directories with videos
#

# Change to project root directory
cd "$(dirname "$0")/.." || exit 1

# =============================================================================
# CONFIGURATION
# =============================================================================

DATES_FILE="dates.txt"
OUTPUT_FOLDER="_output"
ORGANIZED_FOLDER="_organized"

# Excluded special days (grep pattern)
EXCLUDE_PATTERN="Ānāpānasati Day|Āsāḷha Pūjā|Visākha Pūjā|Magha Puja"

# =============================================================================
# FUNCTIONS
# =============================================================================

# Convert month name to number
month_to_num() {
    case "$1" in
        Jan) echo "01" ;;
        Feb) echo "02" ;;
        Mar) echo "03" ;;
        Apr) echo "04" ;;
        May) echo "05" ;;
        Jun) echo "06" ;;
        Jul) echo "07" ;;
        Aug) echo "08" ;;
        Sep) echo "09" ;;
        Oct) echo "10" ;;
        Nov) echo "11" ;;
        Dec) echo "12" ;;
        *) echo "" ;;
    esac
}

# =============================================================================
# MAIN
# =============================================================================

echo "============================================="
echo "Organizing videos by date"
echo "============================================="

# Check if dates file exists
if [ ! -f "$DATES_FILE" ]; then
    echo ">>> Error: Dates file not found: $DATES_FILE"
    exit 1
fi

# Check if output folder exists
if [ ! -d "$OUTPUT_FOLDER" ]; then
    echo ">>> Error: Output folder not found: $OUTPUT_FOLDER"
    exit 1
fi

# Get list of videos
videos=("$OUTPUT_FOLDER"/*.mp4(N))
if [ ${#videos[@]} -eq 0 ]; then
    echo ">>> Error: No videos found in $OUTPUT_FOLDER"
    exit 1
fi

echo ">>> Found ${#videos[@]} videos in $OUTPUT_FOLDER"

# Create organized folder
mkdir -p "$ORGANIZED_FOLDER"

# Parse dates and create directories
video_index=1
dates_created=()

while IFS= read -r line; do
    # Skip empty lines, month headers, and "Date" headers
    [[ -z "$line" ]] && continue
    [[ "$line" =~ ^(January|February|March|April|May|June|July|August|September|October|November|December)$ ]] && continue
    [[ "$line" == "Date" ]] && continue

    # Skip excluded special days
    if echo "$line" | grep -qE "$EXCLUDE_PATTERN"; then
        echo ">>> Skipping (special day): $line"
        continue
    fi

    # Parse date: "Jan 3, 2026 (Saturday) Full Moon" -> "Jan" "3" "2026"
    # Extract month, day, year using regex
    if [[ "$line" =~ ^([A-Za-z]+)[[:space:]]+([0-9]+),?[[:space:]]+([0-9]{4}) ]]; then
        month_name="${match[1]}"
        day="${match[2]}"
        year="${match[3]}"

        # Convert month name to number
        month_num=$(month_to_num "$month_name")

        if [ -z "$month_num" ]; then
            echo ">>> Skipping (invalid month): $line"
            continue
        fi

        # Pad day with zero if needed
        day_padded=$(printf "%02d" "$day")

        # Create directory name
        dir_name="${year}-${month_num}-${day_padded}"
        dir_path="${ORGANIZED_FOLDER}/${dir_name}"

        # Check if we have a video for this date
        if [ $video_index -gt ${#videos[@]} ]; then
            echo ">>> Warning: No more videos available for: $dir_name"
            continue
        fi

        video_file="${videos[$video_index]}"

        # Create directory and move video
        mkdir -p "$dir_path"
        cp "$video_file" "$dir_path/"

        echo ">>> $dir_name <- $(basename "$video_file")"
        dates_created+=("$dir_name")

        ((video_index++))
    fi
done < "$DATES_FILE"

echo "============================================="
echo "Done! Created ${#dates_created[@]} dated directories in $ORGANIZED_FOLDER"
echo "============================================="
