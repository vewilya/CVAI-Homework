#!/bin/bash

# Photogrammetry Automated Capture Script
# Captures webcam images and sends UART commands to rotate object

set -e

# Save original arguments for metadata logging
ORIGINAL_ARGS="$*"
START_TIME_SECONDS=$(date +%s)
START_TIME_FORMATTED=$(date)

# ============ Configuration ============

# UART/Serial port configuration
UART_DEVICE="${UART_DEVICE:-/dev/ttyUSB0}"
UART_BAUD="${UART_BAUD:-115200}"

# Webcam configuration
WEBCAM_DEVICE="${WEBCAM_DEVICE:-/dev/video0}"
WEBCAM_RESOLUTION="${WEBCAM_RESOLUTION:-1920x1080}"
WEBCAM_FORMAT="${WEBCAM_FORMAT:-MJPEG}"

# Start position configuration (degrees)
START_X="${START_X:-0}" # Initial horizontal position
START_Y="${START_Y:-0}" # Initial vertical position

# Movement configuration (degrees per step)
STEP_X="${STEP_X:-15}" # Horizontal rotation step
STEP_Y="${STEP_Y:-30}" # Vertical rotation step

# Capture range (degrees)
RANGE_X="${RANGE_X:-360}" # Full horizontal rotation from start
RANGE_Y="${RANGE_Y:-90}"  # Vertical range from start

# Delay between movement and capture (seconds)
SETTLE_DELAY="${SETTLE_DELAY:-2}"

# Output directory
OUTPUT_DIR="${OUTPUT_DIR:-./photogrammetry_$(date +%Y%m%d_%H%M%S)}"

# Capture tool (fswebcam, ffmpeg, v4l2-ctl)
CAPTURE_TOOL="${CAPTURE_TOOL:-fswebcam}"

# Movement command format
# Available variables: {x}, {y}
MOVE_CMD_FORMAT="${MOVE_CMD_FORMAT:-MOVE {x} {y}}"

# Camera Info variable for basic logging
WEBCAM_INFO="Not Available"

# ============ Functions ============

print_usage() {
  cat <<EOF
Usage: $0 [OPTIONS]

Automated photogrammetry capture script that captures webcam images and
sends movement commands via UART/serial console.

Configuration (can be set via environment or command line):
  UART_DEVICE       Serial device path (default: /dev/ttyUSB0)
  UART_BAUD         Baud rate (default: 115200)
  WEBCAM_DEVICE     Webcam device path (default: /dev/video0)
  WEBCAM_RESOLUTION Resolution (default: 1920x1080)
  WEBCAM_FORMAT     Video format (default: MJPEG)
  START_X           Starting horizontal position (default: 0)
  START_Y           Starting vertical position (default: 0)
  STEP_X            Degrees per horizontal step (default: 15)
  STEP_Y            Degrees per vertical step (default: 30)
  RANGE_X           Total horizontal rotation (default: 360)
  RANGE_Y           Total vertical range (default: 90)
  SETTLE_DELAY      Delay after movement in seconds (default: 2)
  OUTPUT_DIR        Output directory for images
  CAPTURE_TOOL      Tool to use: fswebcam, ffmpeg, v4l2 (default: fswebcam)
  MOVE_CMD_FORMAT   Command format with {x} {y} placeholders

Options:
  -h, --help        Show this help message
  -d, --device      UART device path
  -b, --baud        Baud rate
  -w, --webcam      Webcam device path
  -r, --resolution  Webcam resolution (e.g., 1920x1080)
  --start-x         Starting horizontal position in degrees
  --start-y         Starting vertical position in degrees
  -x, --step-x      Horizontal step in degrees
  -y, --step-y      Vertical step in degrees
  --range-x         Total horizontal range
  --range-y         Total vertical range
  --delay           Settle delay in seconds
  -o, --output      Output directory
  -t, --tool        Capture tool (fswebcam, ffmpeg, v4l2)
  --home            Send home command before starting
  --dry-run         Print commands without executing
  --list-devices    List available video devices and exit

Examples:
  # Basic usage with defaults
  $0

  # Custom configuration with start positions
  $0 -d /dev/ttyACM0 --start-x 90 --start-y 10 -x 10 -y 20

EOF
}

log() {
  echo "[$(date +%H:%M:%S)] $*"
}

error() {
  echo "[ERROR] $*" >&2
  cleanup
  exit 1
}

cleanup() {
  # Close UART file descriptor if open
  if [ -n "$UART_FD" ]; then
    exec {UART_FD}>&-
    log "Closed UART connection"
  fi
}

list_video_devices() {
  log "Available video devices:"
  for device in /dev/video*; do
    if [ -e "$device" ]; then
      echo "  $device"
      if command -v v4l2-ctl >/dev/null 2>&1; then
        v4l2-ctl -d "$device" --info 2>/dev/null | grep -E "Card type|Driver name" | sed 's/^/    /'
      fi
    fi
  done
}

check_dependencies() {
  local missing=()

  # Check capture tool
  case "$CAPTURE_TOOL" in
  fswebcam)
    command -v fswebcam >/dev/null || missing+=("fswebcam")
    ;;
  ffmpeg)
    command -v ffmpeg >/dev/null || missing+=("ffmpeg")
    ;;
  v4l2)
    command -v v4l2-ctl >/dev/null || missing+=("v4l-utils")
    ;;
  esac

  # Check stty for UART communication
  command -v stty >/dev/null || missing+=("stty")

  if [ ${#missing[@]} -gt 0 ]; then
    error "Missing dependencies: ${missing[*]}"
  fi
}

check_webcam() {
  if [ ! -e "$WEBCAM_DEVICE" ]; then
    error "Webcam device not found: $WEBCAM_DEVICE"
  fi

  if [ ! -r "$WEBCAM_DEVICE" ]; then
    error "No read permission for $WEBCAM_DEVICE. Try: sudo chmod 666 $WEBCAM_DEVICE"
  fi

  log "Webcam device: $WEBCAM_DEVICE"

  # Show camera info if v4l2-ctl is available
  if command -v v4l2-ctl >/dev/null 2>&1; then
    WEBCAM_INFO=$(v4l2-ctl -d "$WEBCAM_DEVICE" --info 2>/dev/null | grep "Card type" | cut -d: -f2 | xargs)
    if [ -n "$WEBCAM_INFO" ]; then
      log "Camera: $WEBCAM_INFO"
    else
      WEBCAM_INFO="Unknown (v4l2-ctl could not read info)"
    fi
  fi
}

setup_uart() {
  if [ ! -e "$UART_DEVICE" ]; then
    error "UART device not found: $UART_DEVICE"
  fi

  if [ ! -r "$UART_DEVICE" ] || [ ! -w "$UART_DEVICE" ]; then
    error "No read/write permission for $UART_DEVICE. Try: sudo chmod 666 $UART_DEVICE"
  fi

  log "Configuring UART: $UART_DEVICE at $UART_BAUD baud"
  stty -F "$UART_DEVICE" "$UART_BAUD" cs8 -cstopb -parenb raw -echo ||
    error "Failed to configure UART device"

  # Open UART device for writing and keep it open
  exec {UART_FD}>"$UART_DEVICE"

  if [ -z "$UART_FD" ]; then
    error "Failed to open UART device for persistent connection"
  fi

  log "UART connection established (FD: $UART_FD)"
  sleep 0.5
}

send_uart_command() {
  local cmd="$1"
  if [ "$DRY_RUN" = "true" ]; then
    log "DRY-RUN: Would send: $cmd"
  else
    log "Sending: $cmd"
    echo "$cmd" >&${UART_FD}
    sleep 0.1
  fi
}

capture_image() {
  local filename="$1"
  local max_retries=50
  local attempt=1
  local success=false
  local min_size=1 # 1 MB in bytes

  if [ "$DRY_RUN" = "true" ]; then
    log "DRY-RUN: Would capture: $filename"
    return
  fi

  log "Capturing: $filename"

  case "$CAPTURE_TOOL" in
  fswebcam)
    fswebcam -d "$WEBCAM_DEVICE" \
      -r "$WEBCAM_RESOLUTION" \
      --no-banner \
      --jpeg 95 \
      --save "$filename" 2>/dev/null || error "Image capture failed"
    ;;
  ffmpeg)
    ffmpeg -f v4l2 -input_format mjpeg -framerate 15 -video_size "$WEBCAM_RESOLUTION" \
      -i "$WEBCAM_DEVICE" \
      -vframes 1 \
      -q:v 2 \
      "$filename" -y 2>/dev/null || error "Image capture failed"
    ;;
  v4l2)
    while [ $attempt -le $max_retries ]; do
      echo "------------------------------------------------"
      echo "Capture Attempt: $attempt / $max_retries"

      local tmp_file="${filename}.tmp"

      # Capture using v4l2-ctl
      v4l2-ctl -d "$WEBCAM_DEVICE" \
        --set-fmt-video=width=${WEBCAM_RESOLUTION%x*},height=${WEBCAM_RESOLUTION#*x},pixelformat=MJPG \
        --stream-mmap --stream-count=10 \
        --stream-to="$tmp_file" 2>/dev/null

      if [ -s "$tmp_file" ]; then
        local actual_size=$(stat -c%s "$tmp_file")
        local size_mb=$(echo "scale=2; $actual_size / 1048576" | bc)

        echo "File Size: ${size_mb} MB ($actual_size bytes)"

        if [ "$actual_size" -ge "$min_size" ]; then
          echo "Integrity Check:"
          local info_output=$(jpeginfo -c "$tmp_file")
          echo "  $info_output"

          # UPDATED: More flexible grep to catch "OK" even without brackets
          if echo "$info_output" | grep -iwq "OK"; then
            mv "$tmp_file" "$filename"
            echo "SUCCESS: Image validated and saved to $filename"
            success=true
            break
          else
            echo "RESULT: FAILED - JPEG is malformed or corrupted."
          fi
        else
          echo "RESULT: FAILED - Image is smaller than 1MB requirement."
        fi
      else
        echo "RESULT: FAILED - Zero bytes captured."
      fi

      rm -f "$tmp_file"
      echo "Retrying in 0.5s..."
      sleep 0.5
      attempt=$((attempt + 1))
    done
    ;;
  esac
}

move_and_capture() {
  local x=$1
  local y=$2
  local index=$3

  # Generate movement command - properly substitute {x} and {y}
  move_cmd="${MOVE_CMD_FORMAT//\{x /$x }"
  move_cmd="${move_cmd//\{y\}\}/$y}"

  # Send movement command
  send_uart_command "$move_cmd"

  # Wait for movement to settle
  sleep "$SETTLE_DELAY"

  # Capture image from webcam
  local filename=$(printf "%s/img_%04d_x%03d_y%03d.jpg" "$OUTPUT_DIR" "$index" "$x" "$y")
  capture_image "$filename"
}

# ============ Main Script ============

trap cleanup EXIT INT TERM

# Parse command line arguments
DRY_RUN=false
SEND_HOME=false

while [[ $# -gt 0 ]]; do
  case $1 in
  -h | --help)
    print_usage
    exit 0
    ;;
  --list-devices)
    list_video_devices
    exit 0
    ;;
  -d | --device)
    UART_DEVICE="$2"
    shift 2
    ;;
  -b | --baud)
    UART_BAUD="$2"
    shift 2
    ;;
  -w | --webcam)
    WEBCAM_DEVICE="$2"
    shift 2
    ;;
  -r | --resolution)
    WEBCAM_RESOLUTION="$2"
    shift 2
    ;;
  --start-x)
    START_X="$2"
    shift 2
    ;;
  --start-y)
    START_Y="$2"
    shift 2
    ;;
  -x | --step-x)
    STEP_X="$2"
    shift 2
    ;;
  -y | --step-y)
    STEP_Y="$2"
    shift 2
    ;;
  --range-x)
    RANGE_X="$2"
    shift 2
    ;;
  --range-y)
    RANGE_Y="$2"
    shift 2
    ;;
  --delay)
    SETTLE_DELAY="$2"
    shift 2
    ;;
  -o | --output)
    OUTPUT_DIR="$2"
    shift 2
    ;;
  -t | --tool)
    CAPTURE_TOOL="$2"
    shift 2
    ;;
  --home)
    SEND_HOME=true
    shift
    ;;
  --dry-run)
    DRY_RUN=true
    shift
    ;;
  *) error "Unknown option: $1" ;;
  esac
done

# Calculate total images
num_x_steps=$(((RANGE_X + STEP_X - 1) / STEP_X))
num_y_steps=$(((RANGE_Y + STEP_Y - 1) / STEP_Y + 1))
total_images=$((num_x_steps * num_y_steps))

log "=== Photogrammetry Webcam Capture Configuration ==="
log "UART Device:     $UART_DEVICE @ $UART_BAUD baud"
log "Webcam Device:   $WEBCAM_DEVICE"
log "Resolution:      $WEBCAM_RESOLUTION"
log "Start Pos:       X=$START_X° Y=$START_Y°"
log "Step Size:       X=$STEP_X° Y=$STEP_Y°"
log "Range:           X=$RANGE_X° Y=$RANGE_Y°"
log "Total images:    $total_images ($num_x_steps x $num_y_steps)"
log "=================================================="

check_dependencies
check_webcam
setup_uart

mkdir -p "$OUTPUT_DIR"
log "Created output directory: $OUTPUT_DIR"

if [ "$SEND_HOME" = "true" ]; then
  log "Sending home command..."
  send_uart_command "HOME"
  sleep 3
fi

# Main capture loop
log "Starting capture sequence..."
index=0

for ((y = START_Y; y <= START_Y + RANGE_Y; y += STEP_Y)); do
  for ((x = START_X; x < START_X + RANGE_X; x += STEP_X)); do
    index=$((index + 1))
    log "Progress: $index/$total_images (X=$x° Y=$y°)"
    move_and_capture "$x" "$y" "$index"
  done
done

END_TIME_SECONDS=$(date +%s)
DURATION=$((END_TIME_SECONDS - START_TIME_SECONDS))

log "Capture complete! Images saved to: $OUTPUT_DIR"

# ============ Metadata Dump ============
log "Dumping comprehensive metadata to: $OUTPUT_DIR/metadata.txt"

{
  echo "==================================================="
  echo "       PHOTOGRAMMETRY CAPTURE METADATA DUMP        "
  echo "==================================================="
  echo ""

  echo "=== EXECUTION CONTEXT ==="
  echo "Start Time:        $START_TIME_FORMATTED"
  echo "End Time:          $(date)"
  echo "Total Duration:    $((DURATION / 60)) minutes and $((DURATION % 60)) seconds"
  echo "Total Images:      $index / $total_images planned"
  echo "Command Executed:  $0 $ORIGINAL_ARGS"
  echo "Dry Run Mode:      $DRY_RUN"
  echo "Sent Home Command: $SEND_HOME"
  echo ""

  echo "=== SYSTEM INFORMATION ==="
  echo "Hostname:          $(hostname)"
  echo "User:              $(whoami)"
  echo "Kernel/OS:         $(uname -a)"
  echo ""

  echo "=== SCRIPT CONFIGURATION VARIABLES ==="
  echo "UART_DEVICE:       $UART_DEVICE"
  echo "UART_BAUD:         $UART_BAUD"
  echo "WEBCAM_DEVICE:     $WEBCAM_DEVICE"
  echo "WEBCAM_RESOLUTION: $WEBCAM_RESOLUTION"
  echo "WEBCAM_FORMAT:     $WEBCAM_FORMAT"
  echo "START_X:           $START_X"
  echo "START_Y:           $START_Y"
  echo "STEP_X:            $STEP_X"
  echo "STEP_Y:            $STEP_Y"
  echo "RANGE_X:           $RANGE_X"
  echo "RANGE_Y:           $RANGE_Y"
  echo "SETTLE_DELAY:      $SETTLE_DELAY"
  echo "OUTPUT_DIR:        $OUTPUT_DIR"
  echo "CAPTURE_TOOL:      $CAPTURE_TOOL"
  echo "MOVE_CMD_FORMAT:   $MOVE_CMD_FORMAT"
  echo ""

  echo "=== UART HARDWARE DUMP (stty -a) ==="
  if [ -e "$UART_DEVICE" ] && command -v stty >/dev/null; then
    stty -F "$UART_DEVICE" -a 2>/dev/null || echo "Failed to read stty configurations."
  else
    echo "UART device or stty tool unavailable."
  fi
  echo ""

  echo "=== CAMERA HARDWARE DUMP (v4l2-ctl --all) ==="
  if command -v v4l2-ctl >/dev/null 2>&1; then
    v4l2-ctl -d "$WEBCAM_DEVICE" --all 2>/dev/null || echo "Failed to query full camera info."
  else
    echo "v4l2-ctl is not installed. Full camera dump unavailable."
  fi
  echo "==================================================="
} >"$OUTPUT_DIR/metadata.txt"

log "Script finished successfully."
