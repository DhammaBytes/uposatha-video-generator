#!/bin/zsh
#
# Chant Video Resizer
# ===================
# Resizes chant videos to 1280x720 resolution for compatibility.
#
# Behavior:
#   - Already 1280x720: copied without re-encoding (fast)
#   - Larger with same aspect ratio: scaled down to 1280x720
#   - Different aspect ratio: scaled to fit height 720, padded with black
#     bars to reach width 1280 (letterboxing/pillarboxing)
#
# Usage:
#   ./resize_chants.sh
#
# Input:  chants/ folder (mp4, mov, avi, mkv files)
# Output: chants_resized/ folder
#

# Change to project root directory
cd "$(dirname "$0")/.." || exit 1

# =============================================================================
# CONFIGURATION
# =============================================================================

VIDEO_FOLDER="chants"
OUTPUT_FOLDER="chants_resized"

# Create output folder if it doesn't exist
mkdir -p "$OUTPUT_FOLDER"

echo "============================================="
echo "Resizing chant videos to 1280x720"
echo "============================================="
echo ">>> Input folder: $VIDEO_FOLDER"
echo ">>> Output folder: $OUTPUT_FOLDER"

# Process each video file
for video_file in "$VIDEO_FOLDER"/*.(mp4|mov|avi|mkv); do
    # Skip if no files match
    [ -f "$video_file" ] || continue

    # Skip .DS_Store
    [[ "$video_file" == *".DS_Store" ]] && continue

    filename=$(basename "$video_file")
    output_file="${OUTPUT_FOLDER}/${filename%.*}.mp4"

    echo "============================================="
    echo ">>> Processing: $video_file"

    # Get video dimensions
    width=$(ffprobe -v error -select_streams v:0 -show_entries stream=width -of csv=p=0 "$video_file")
    height=$(ffprobe -v error -select_streams v:0 -show_entries stream=height -of csv=p=0 "$video_file")

    echo ">>> Original dimensions: ${width}x${height}"

    # Check if already 1280x720
    if [[ "$width" -eq 1280 && "$height" -eq 720 ]]; then
        echo ">>> Already 1280x720, copying without re-encoding"
        cp "$video_file" "$output_file"
        continue
    fi

    # Calculate aspect ratios (multiply by 1000 for integer comparison)
    original_ar=$((width * 1000 / height))
    target_ar=$((1280 * 1000 / 720))  # ~1777

    echo ">>> Original AR: $original_ar, Target AR: $target_ar"

    # Resize video:
    # - scale to fit within 1280x720 (maintaining aspect ratio)
    # - pad with black bars to exactly 1280x720 (centering the video)
    ffmpeg -y -i "$video_file" \
        -filter_complex "
            [0:v]scale=1280:720:force_original_aspect_ratio=decrease,pad=1280:720:(ow-iw)/2:(oh-ih)/2,setdar=16:9,setsar=1[v]
        " \
        -map "[v]" -map '0:a?' \
        -c:v libx264 -c:a aac -b:a 192k -ac 2 -ar 44100 \
        -g 180 -x264-params "keyint=180:min-keyint=180" \
        "$output_file"

    if [ -f "$output_file" ]; then
        echo ">>> Created: $output_file"
    else
        echo ">>> Error: Failed to create: $output_file"
    fi
done

echo "============================================="
echo "Done! Resized videos are in: $OUTPUT_FOLDER"
echo "============================================="
