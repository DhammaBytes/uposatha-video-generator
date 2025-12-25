# Metta Parisa Uposatha Video Generator

Scripts for generating meditation videos for Metta Parisa Uposatha meditation meetings.

## Directory Structure

```
uposatha/
├── scripts/                    # All generation scripts
│   ├── uposatha_generator.sh   # Main video generator
│   ├── generate_intro.sh       # Creates Intro.mp4 from image
│   ├── generate_ending.sh      # Creates Ending.mp4 sequence
│   └── resize_chants.sh        # Resizes chant videos to 1280x720
├── static/                     # Static video assets (REQUIRED)
│   ├── Intro.png               # Intro image (for generate_intro.sh)
│   ├── Intro.mp4               # Intro video (generated or provided)
│   ├── Bows x6.mp4             # Bowing sequence video
│   ├── Bowl.mp4                # Singing bowl video
│   └── Dedication.mp4          # Dedication chant video
├── chants/                     # Chant videos (REQUIRED)
│   └── *.mp4                   # Pali chanting videos (1280x720 recommended)
├── photos/                     # Background photos (REQUIRED)
│   └── *.jpg/*.png             # Photos for talk segments
├── talks/                      # Dhamma talk audio files (REQUIRED)
│   └── *.mp3                   # MP3 audio files
├── _output/                    # Generated videos (created automatically)
└── chants_resized/             # Resized chants (created by resize_chants.sh)
```

## Required Files

### static/ folder
| File | Description |
|------|-------------|
| `Intro.mp4` | Opening title video (5 seconds recommended) |
| `Bows x6.mp4` | Six bows video |
| `Bowl.mp4` | Singing bowl transition video |
| `Dedication.mp4` | Short goodwill dedication video (used in ending) |

### Other folders
- **chants/**: Pali chanting videos, should be 1280x720 resolution
- **photos/**: Background images displayed during Dhamma talks
- **talks/**: MP3 audio files of Dhamma talks

## Video Sequence

Each generated Uposatha video follows this sequence:

1. **Intro** - Title screen
2. **Bows x6** - Six bows
3. **Chant** - Pali chanting video (rotates every 4 talks)
4. **Bowl** - Singing bowl transition
5. **Talk** - Photo background with Dhamma talk audio

## Scripts

### Main Generator

Generates complete Uposatha videos by combining all segments.

**What it does:**
1. Collects audio talks (MP3), photos, and chant videos from their folders
2. Sorts talks and chants alphabetically; shuffles photos randomly
3. For each talk, creates a video with the photo as background
4. Scales and pads all content to 1280x720 resolution
5. Normalizes audio (converts to AAC, boosts volume 3x for talks)
6. Concatenates: Intro → Bows → Chant → Bowl → Talk with photo
7. Rotates to the next chant video every 4 talks
8. Sets frequent keyframes for smooth playback in all players

```bash
./scripts/uposatha_generator.sh [OPTIONS]
```

**Options:**
| Option | Description |
|--------|-------------|
| `--test` or `-t` | Generate only one random video for testing |

**Examples:**
```bash
# Generate all videos
./scripts/uposatha_generator.sh

# Test run with one random video
./scripts/uposatha_generator.sh --test
```

**Output:** Videos are saved to `_output/` folder, named after the talk MP3 file.

---

### Intro Generator

Creates `Intro.mp4` from a static image with silent audio track.

```bash
./scripts/generate_intro.sh [DURATION]
```

**Arguments:**
| Argument | Description |
|----------|-------------|
| `DURATION` | Video length in seconds (default: 20) |

**Examples:**
```bash
./scripts/generate_intro.sh        # Creates 20-second intro
./scripts/generate_intro.sh 10     # Creates 10-second intro
```

**Input:** `static/Intro.png`
**Output:** `static/Intro.mp4`

---

### Ending Generator

Creates `Ending.mp4` by concatenating Bowl, Dedication, and Bows videos.

```bash
./scripts/generate_ending.sh
```

**Sequence:**
1. Bowl.mp4 - Singing bowl
2. Dedication.mp4 - Goodwill dedication
3. Bows x6.mp4 - Closing bows

**Output:** `static/Ending.mp4`

---

### Chant Resizer

Resizes chant videos to 1280x720 resolution for compatibility.

```bash
./scripts/resize_chants.sh
```

**Behavior:**
- Already 1280x720: copied without re-encoding
- Larger with same aspect ratio: scaled down
- Different aspect ratio: scaled to fit height 720, padded with black bars to width 1280

**Input:** `chants/` folder
**Output:** `chants_resized/` folder

---

### Date Organizer

Organizes generated videos into dated directories based on `dates.txt`.

```bash
./scripts/organize_by_date.sh
```

**Behavior:**
- Parses dates from `dates.txt` (format: "Jan 3, 2026 (Saturday) Full Moon")
- Creates directories like `2026-01-03`
- Copies videos from `_output/` into dated directories
- Skips special days: Ānāpānasati Day, Āsāḷha Pūjā, Visākha Pūjā, Magha Puja

**Input:** `dates.txt`, `_output/*.mp4`
**Output:** `_organized/YYYY-MM-DD/` directories

## Technical Details

### Video Specifications
- Resolution: 1280x720 (720p)
- Aspect ratio: 16:9
- Video codec: H.264 (libx264)
- Audio codec: AAC
- Audio sample rate: 44100 Hz
- Audio channels: Stereo

### Encoding Settings
All scripts use consistent encoding to avoid concatenation issues:
- Keyframe interval: 180 frames
- DAR/SAR normalization for seamless transitions
- Audio volume boost: 3x (for talks)

## Requirements

- zsh shell (default on macOS; available on Linux and Windows WSL)
- ffmpeg and ffprobe installed
- Perl (included with macOS and most Linux distributions)

## Troubleshooting

**"shuf not found" error:** The scripts use Perl for shuffling (macOS compatible).

**Videos not concatenating smoothly:** Ensure all source videos are 1280x720. Use `resize_chants.sh` to fix chant videos.

**Audio too quiet:** Talk audio is boosted 3x by default. Edit `volume=3` in `uposatha_generator.sh` to adjust.
