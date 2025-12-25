#!/bin/zsh
#
# Ending Video Generator
# ======================
# Creates Ending.mp4 by concatenating the closing sequence videos.
#
# Sequence:
#   1. Bowl.mp4       - Singing bowl
#   2. Dedication.mp4 - Goodwill dedication
#   3. Bows x6.mp4    - Closing bows
#
# Usage:
#   ./generate_ending.sh
#
# Input:  static/Bowl.mp4, static/Dedication.mp4, static/Bows x6.mp4
# Output: static/Ending.mp4
#

# Change to project root directory
cd "$(dirname "$0")/.." || exit 1

# =============================================================================
# CONFIGURATION
# =============================================================================

STATIC_FOLDER="static"
OUTPUT_VIDEO="${STATIC_FOLDER}/Ending.mp4"

# Input videos in sequence order
bowl_video="${STATIC_FOLDER}/Bowl.mp4"
dedication_video="${STATIC_FOLDER}/Dedication.mp4"
bowing_video="${STATIC_FOLDER}/Bows x6.mp4"

echo "============================================="
echo "Generating Ending video"
echo "============================================="
echo ">>> Bowl video: $bowl_video"
echo ">>> Dedication video: $dedication_video"
echo ">>> Bowing video: $bowing_video"
echo ">>> Output video: $OUTPUT_VIDEO"

# Check if all input videos exist
for video in "$bowl_video" "$dedication_video" "$bowing_video"; do
    if [ ! -f "$video" ]; then
        echo ">>> Error: Video not found: $video"
        exit 1
    fi
done

# Concatenate videos using the same filter_complex approach as main script
# This ensures consistent encoding and avoids inter-video problems
ffmpeg -y \
    -i "$bowl_video" -i "$dedication_video" -i "$bowing_video" \
    -filter_complex "
        [0:v]setpts=PTS-STARTPTS,setdar=16:9,setsar=1[v0];
        [1:v]setpts=PTS-STARTPTS,setdar=16:9,setsar=1[v1];
        [2:v]setpts=PTS-STARTPTS,setdar=16:9,setsar=1[v2];
        [v0][v1][v2]concat=n=3:v=1:a=0[v];
        [0:a][1:a][2:a]concat=n=3:v=0:a=1[a]
    " \
    -map "[v]" -map "[a]" \
    -c:v libx264 -c:a aac -b:a 192k -ac 2 -ar 44100 -strict experimental \
    "$OUTPUT_VIDEO"

if [ -f "$OUTPUT_VIDEO" ]; then
    echo ">>> Successfully created: $OUTPUT_VIDEO"
else
    echo ">>> Error: Failed to create video"
    exit 1
fi
