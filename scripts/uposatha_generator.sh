#!/bin/zsh
#
# Metta Parisa Uposatha Video Generator
# ======================================
# Generates meditation videos for Uposatha meetings.
#
# Each video follows this sequence:
#   1. Intro.mp4        - Title screen
#   2. Bows x6.mp4      - Six bows
#   3. Chant video      - Pali chanting (rotates every 4 talks)
#   4. Bowl.mp4         - Singing bowl transition
#   5. Photo + Talk     - Background photo with Dhamma talk audio
#
# Usage:
#   ./uposatha_generator.sh           # Generate all videos
#   ./uposatha_generator.sh --test    # Generate one random video for testing
#   ./uposatha_generator.sh -t        # Same as --test
#
# Output: Videos saved to _output/ folder
#

# Change to project root directory
cd "$(dirname "$0")/.." || exit 1

# =============================================================================
# CONFIGURATION
# =============================================================================

# Folders containing the files
PHOTO_FOLDER="photos"
AUDIO_FOLDER="talks"
VIDEO_FOLDER="chants"
STATIC_FOLDER="static"

intro_video="${STATIC_FOLDER}/Intro.mp4"
bowing_video="${STATIC_FOLDER}/Bows x6.mp4"
bowl_video="${STATIC_FOLDER}/Bowl.mp4"

# Test mode flag - set to true to generate only one random video
TEST_MODE=false
if [[ "$1" == "--test" || "$1" == "-t" ]]; then
    TEST_MODE=true
    echo ">>> TEST MODE: Will generate only one random video"
fi

# Output folder for the final videos
OUTPUT_FOLDER="_output"

# Create output folder if it doesn't exist
mkdir -p "$OUTPUT_FOLDER"
echo "Output folder: $OUTPUT_FOLDER"

# =============================================================================
# COLLECT SOURCE FILES
# =============================================================================

# Get the list of files from the folders (safely handling spaces in filenames)
audio_list=()
photo_list=()
video_list=()

# Will hold shuffled photos for random assignment to talks
shuffled_photos=()

echo "Getting audio files..."
while IFS= read -r -d $'\0' audio_file; do
    if [[ "$audio_file" != *".DS_Store" ]]; then
        audio_list+=("$audio_file")
    fi
done < <(find "$AUDIO_FOLDER" -type f -name "*.mp3" -print0)

echo "Getting photo files..."
while IFS= read -r -d $'\0' photo_file; do
    if [[ "$photo_file" != *".DS_Store" ]]; then
        photo_list+=("$photo_file")
    fi
done < <(find "$PHOTO_FOLDER" -type f -print0)

echo "Getting video files..."
while IFS= read -r -d $'\0' video_file; do
    if [[ "$video_file" != *".DS_Store" ]]; then
        video_list+=("$video_file")
    fi
done < <(find "$VIDEO_FOLDER" -type f -print0)

# Log the lists of files before sorting
echo "Audio files found: ${#audio_list[@]}"
echo "Photo files found: ${#photo_list[@]}"
echo "Video files found: ${#video_list[@]}"

# Sort the video and audio arrays by filename in ascending order using zsh's array sorting
IFS=$'\n' audio_list=($(sort <<<"${audio_list[*]}"))
unset IFS

IFS=$'\n' video_list=($(sort <<<"${video_list[*]}"))
unset IFS

# Shuffle the list of photos (using perl for macOS compatibility)
IFS=$'\n' shuffled_photos=($(printf "%s\n" "${photo_list[@]}" | perl -MList::Util=shuffle -e 'print shuffle(<STDIN>)'))
unset IFS

# In test mode, select only one random audio file and random video
if [[ "$TEST_MODE" == true ]]; then
    random_audio_index=$((RANDOM % ${#audio_list[@]} + 1))
    random_video_index=$((RANDOM % ${#video_list[@]} + 1))
    audio_list=("${audio_list[$random_audio_index]}")
    video_list=("${video_list[$random_video_index]}")
    echo ">>> Selected random audio: ${audio_list[1]}"
    echo ">>> Selected random chant: ${video_list[1]}"
fi

# =============================================================================
# MAIN PROCESSING LOOP
# =============================================================================

# Initialize indices (zsh arrays are 1-based)
audio_index=1
video_index=1
photo_index=1

# Loop through each audio file
for audio_file in "${audio_list[@]}"
do
    echo "============================================="
    echo "============================================="
    echo "============================================="
    echo "============================================="
    echo "============================================="
    echo ">>> Processing audio file: $audio_file"

    # Get paths to the files
    audio_path="$audio_file"

    # Ensure that video_index is within bounds (zsh arrays are 1-based)
    if [ $video_index -gt "${#video_list[@]}" ]; then
        echo ">>> Error: Video index is out of bounds: $video_index"
        break
    fi

    video_path="${video_list[$video_index]}"

    echo ">>> Videos: $video_list"
    echo ">>> Using video file: $video_path"

    # Ensure that the video file exists
    if [ ! -f "$video_path" ]; then
        echo ">>> Error: Video file does not exist: $video_path"
        continue
    fi

    # Ensure the photo array is correctly accessed
    photo_path="${shuffled_photos[$photo_index]}"
    padded_photo_path=""
    echo ">>> Using photo file: $photo_path"

    # Check if photo path is valid
    if [[ -z "$photo_path" || ! -f "$photo_path" ]]; then
        echo ">>> Error: Photo file not found or empty path: $photo_path (index: $photo_index)"
        echo ">>> Available photos: ${#shuffled_photos[@]}"
        continue
    fi

    # Get image dimensions using ffprobe
    image_width=$(ffprobe -v error -select_streams v:0 -show_entries stream=width -of csv=p=0 "$photo_path")
    image_height=$(ffprobe -v error -select_streams v:0 -show_entries stream=height -of csv=p=0 "$photo_path")

    # Check if both width and height are smaller than 1280 and 720
    if (( image_width < 1280 && image_height < 720 )); then
        echo ">>> Photo is smaller than 1280x720, adding padding."

        # Add padding to center the image in a 1280x720 resolution
        padded_photo_path="${OUTPUT_FOLDER}/padded_$(basename "$photo_path")"
        ffmpeg -y -i "$photo_path" -vf "pad=1280:720:(1280-iw)/2:(720-ih)/2" "$padded_photo_path"

        # Update photo_path to the padded image
        photo_path="$padded_photo_path"
    else
        echo ">>> Photo is already larger than or equal to 1280x720, no padding needed."
    fi

    # Check if the audio file exists
    if [ ! -f "$audio_path" ]; then
        echo ">>> Error: Audio file not found: $audio_path"
        continue
    fi

    # Get the duration of the audio file
    audio_duration=$(ffmpeg -i "$audio_path" 2>&1 | grep Duration | awk '{print $2}' | tr -d ,)
    if [[ -z "$audio_duration" ]]; then
        echo ">>> Error: Could not get duration for audio file: $audio_path"
        continue
    fi
    audio_seconds=$(echo $audio_duration | awk -F: '{print ($1 * 3600) + ($2 * 60) + $3}')
    echo ">>> Audio duration (seconds): $audio_seconds"

    # Get the duration of the video
    video_duration=$(ffmpeg -i "$video_path" 2>&1 | grep Duration | awk '{print $2}' | tr -d ,)
    if [[ -z "$video_duration" ]]; then
        echo ">>> Error: Could not get duration for video file: $video_path"
        continue
    fi
    video_seconds=$(echo $video_duration | awk -F: '{print ($1 * 3600) + ($2 * 60) + $3}')
    echo ">>> Video duration (seconds): $video_seconds"

    # Define the temporary file path for the re-encoded audio
    temp_audio="${OUTPUT_FOLDER}/temp.aac"

    # Convert the MP3 audio to AAC in the temporary file
    echo ">>> Re-encoding audio from MP3 to AAC with volume amplification: $temp_audio"
    ffmpeg -y -i "$audio_path" -c:a aac -ac 2 -ar 44100 -t "$audio_seconds" -filter:a "volume=3" "$temp_audio"

    # Check if the temporary audio was created successfully
    if [ ! -f "$temp_audio" ]; then
        echo ">>> Error: Failed to create temporary audio file: $temp_audio"
        continue
    fi

    # Create the intermediate file with the static photo and audio
    photo_video="${OUTPUT_FOLDER}/temp.mp4"
    echo ">>> Creating temporary video: $photo_video"

    # Scale the photo to fit within 1280x720 and center it, maintaining aspect ratio
    ffmpeg -y -loop 1 -framerate 1 -t "$audio_seconds" -i "$photo_path" -i "$temp_audio" \
        -c:v libx264 -c:a copy -strict experimental -shortest \
        -g 1 \
        -filter:v "scale=1280:720:force_original_aspect_ratio=decrease,pad=1280:720:(ow-iw)/2:(oh-ih)/2" \
        "$photo_video"

    # Check if the temporary video was created successfully
    if [ ! -f "$photo_video" ]; then
        echo ">>> Error: Failed to create temporary video file: $photo_video"
        continue
    fi

    # Normalize both audio properties (sample rate, channels, codec)
    if [[ "$TEST_MODE" == true ]]; then
        final_video="${OUTPUT_FOLDER}/TEST_$(basename "${audio_file%.*}.mp4")"
    else
        final_video="${OUTPUT_FOLDER}/$(basename "${audio_file%.*}.mp4")"
    fi
    echo ">>> Normalizing and creating final video: $final_video"

    # Concatenate videos and handle audio separately
    ffmpeg -y \
        -i "$intro_video" -i "$bowing_video" -i "$video_path" -i "$bowl_video" -i "$photo_video" \
        -filter_complex "
            [0:v]setpts=PTS-STARTPTS,setdar=16:9,setsar=1[v0];
            [1:v]setpts=PTS-STARTPTS,setdar=16:9,setsar=1[v1];
            [2:v]setpts=PTS-STARTPTS,setdar=16:9,setsar=1[v2];
            [3:v]setpts=PTS-STARTPTS,setdar=16:9,setsar=1[v3];
            [4:v]setpts=PTS-STARTPTS,setdar=16:9,setsar=1[v4];
            [v0][v1][v2][v3][v4]concat=n=5:v=1:a=0[v];
            [0:a][1:a][2:a][3:a][4:a]concat=n=5:v=0:a=1[a]
        " \
        -map "[v]" -map "[a]" \
        -c:v libx264 -c:a aac -b:a 192k -ac 2 -ar 44100 -strict experimental \
        "$final_video"

    # Check if the final video was created successfully
    if [ ! -f "$final_video" ]; then
        echo "Error: Failed to create final video file: $final_video"
        continue
    fi

    echo "Final video created: $final_video"

    # Clean up the intermediate files
    rm "$photo_video" "$temp_audio"
    echo ">>> Cleaned up temporary files: $photo_video, $temp_audio"

    # Clean up the temporary padded photo file if it exists
    if [ -f "$padded_photo_path" ]; then
        rm "$padded_photo_path"
        echo ">>> Removed temporary padded photo file: $padded_photo_path"
    fi

    # Move to the next photo and video
    ((photo_index++))
    if [ "$photo_index" -gt "${#shuffled_photos[@]}" ]; then
        photo_index=1  # Reset to 1-based index
    fi

    ((audio_index++))
    # Switch to the next video every 4 audio files (i.e., on the 5th iteration)
    if [ $(((audio_index - 1) % 4)) -eq 0 ]; then
        ((video_index++))
        if [ "$video_index" -gt "${#video_list[@]}" ]; then
            video_index=1  # Reset to 1-based index
        fi
    fi
done
