#!/bin/zsh
#
# Intro Video Generator
# =====================
# Creates Intro.mp4 from a static image (Intro.png) with a set duration.
# The video includes a silent audio track for compatibility with concatenation.
#
# Usage:
#   ./generate_intro.sh [DURATION]
#
# Arguments:
#   DURATION  Video length in seconds (default: 20)
#
# Examples:
#   ./generate_intro.sh        # Creates 20-second intro
#   ./generate_intro.sh 10     # Creates 10-second intro
#
# Input:  static/Intro.png
# Output: static/Intro.mp4
#

# Change to project root directory
cd "$(dirname "$0")/.." || exit 1

# =============================================================================
# CONFIGURATION
# =============================================================================

STATIC_FOLDER="static"
INPUT_IMAGE="${STATIC_FOLDER}/Intro.png"
OUTPUT_VIDEO="${STATIC_FOLDER}/Intro.mp4"

# Duration in seconds - can be overridden by command line argument
DURATION=${1:-20}

echo "============================================="
echo "Generating Intro video"
echo "============================================="
echo ">>> Input image: $INPUT_IMAGE"
echo ">>> Output video: $OUTPUT_VIDEO"
echo ">>> Duration: $DURATION seconds"

# Check if input image exists
if [ ! -f "$INPUT_IMAGE" ]; then
    echo ">>> Error: Input image not found: $INPUT_IMAGE"
    exit 1
fi

# Generate video from static image
# - Scale to fit 1280x720, maintaining aspect ratio
# - Add black padding if needed to center the image
# - Use same encoding settings as main script for compatibility
ffmpeg -y \
    -loop 1 -framerate 30 -t "$DURATION" -i "$INPUT_IMAGE" \
    -f lavfi -t "$DURATION" -i anullsrc=channel_layout=stereo:sample_rate=44100 \
    -filter_complex "[0:v]scale=1280:720:force_original_aspect_ratio=decrease,pad=1280:720:(ow-iw)/2:(oh-ih)/2[v]" \
    -map "[v]" -map 1:a \
    -c:v libx264 -pix_fmt yuv420p \
    -g 180 -x264-params "keyint=180:min-keyint=180" \
    -c:a aac -ac 2 -ar 44100 \
    -shortest \
    "$OUTPUT_VIDEO"

if [ -f "$OUTPUT_VIDEO" ]; then
    echo ">>> Successfully created: $OUTPUT_VIDEO"
else
    echo ">>> Error: Failed to create video"
    exit 1
fi
