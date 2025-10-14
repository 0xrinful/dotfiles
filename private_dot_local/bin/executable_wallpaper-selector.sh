#!/bin/bash

# Wallpaper Selector with Preview
# Requires: rofi, imagemagick (for thumbnails)

if pkill -x rofi; then
  exit 0
fi

WALLPAPER_DIR="$HOME/.config/swww/wallpapers"
CACHE_DIR="$HOME/.cache/wallpaper-selector"
CURRENT_WALLPAPER_FILE="$HOME/.config/swww/current_wallpaper.txt"
THUMB_SIZE="500x400"
ROFI_THEME="wallpaper-selector.rasi"

# Create cache directory if it doesn't exist
mkdir -p "$CACHE_DIR"

# Generate thumbnails for wallpapers
generate_thumbnails() {
  for img in "$WALLPAPER_DIR"/*{.jpg,.jpeg,.png,.webp}; do
    [ -f "$img" ] || continue

    filename=$(basename "$img")
    thumb="$CACHE_DIR/${filename%.*}.png"

    # Only generate if thumbnail doesn't exist or is older than original
    if [ ! -f "$thumb" ] || [ "$img" -nt "$thumb" ]; then
      convert "$img" -resize "$THUMB_SIZE^" -gravity center -extent "$THUMB_SIZE" "$thumb" 2>/dev/null
    fi
  done
}

# Build rofi menu with image previews
select_wallpaper() {
  local options=""
  local images=()
  local current_wallpaper=""
  local selected_index=0
  local index=0

  # Read current wallpaper name
  if [ -f "$CURRENT_WALLPAPER_FILE" ]; then
    current_wallpaper=$(cat "$CURRENT_WALLPAPER_FILE")
  fi

  for img in "$WALLPAPER_DIR"/*{.jpg,.jpeg,.png,.webp}; do
    [ -f "$img" ] || continue

    filename=$(basename "$img")
    thumb="$CACHE_DIR/${filename%.*}.png"

    # Check if this is the current wallpaper
    if [ "$filename" = "$current_wallpaper" ]; then
      selected_index=$index
    fi

    # Add to options with icon
    options+="${filename}\0icon\x1f${thumb}\n"
    images+=("$img")
    ((index++))
  done

  # Show rofi with custom theme, pre-selecting current wallpaper
  selected=$(echo -en "$options" | rofi -dmenu \
    -i \
    -p "Select Wallpaper" \
    -theme "$ROFI_THEME" \
    -show-icons \
    -selected-row "$selected_index")

  if [ -n "$selected" ]; then
    # Find the full path of selected wallpaper
    for img in "${images[@]}"; do
      if [ "$(basename "$img")" = "$selected" ]; then
        set-wallpaper.sh "$img"
        (sleep 0.5 && notify-send "Wallpaper Changed" "Now using: $selected" -i "$img" -t 5000) &
        break
      fi
    done
  fi
}

# Main
echo "Generating thumbnails..."
generate_thumbnails
select_wallpaper
