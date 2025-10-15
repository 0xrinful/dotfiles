#!/usr/bin/env bash

#===============================================================================
# Wallpaper Manager for swww
# Usage:
#   set-wallpaper           → Restore saved wallpaper (for startup)
#   set-wallpaper <file>    → Set new wallpaper
#===============================================================================

### Configuration
WALL_DIR="$HOME/.config/swww/wallpapers"
COLORS_DIR="$HOME/.config/swww/colors"
CURRENT_FILE="$HOME/.config/swww/current_wallpaper.txt"

### Transition settings
TRANSITION_TYPE="fade"
TRANSITION_FPS="60"
TRANSITION_DURATION="1"

apply_colors() {
  wall_name="${1##*/}"
  wall_name="${wall_name%.*}"
  template="${COLORS_DIR}/$wall_name.dcol"

  if [ ! -f "$template" ]; then
    wallbash.sh "$1" "$COLORS_DIR/$wall_name"
  fi

  wallbash-apply.sh "$template"
}

apply_wallpaper() {
  local wallpaper="$1"

  if [ "$wallpaper" = "random" ]; then
    wallpaper="$(find "$WALL_DIR" -type f | shuf -n1)"
  fi

  # If passed a basename (just filename), make it absolute inside WALL_DIR
  if [ ! -f "$wallpaper" ]; then
    wallpaper="$WALL_DIR/$wallpaper"
  fi

  if [ ! -f "$wallpaper" ]; then
    echo "set-wallpaper: file not found: $wallpaper" >&2
    return 1
  fi

  apply_colors "$wallpaper"

  # Apply wallpaper with transitions
  swww img "$wallpaper" \
    --transition-type "$TRANSITION_TYPE" \
    --transition-fps "$TRANSITION_FPS" \
    --transition-duration "$TRANSITION_DURATION"

  # Save current wallpaper (basename only)
  basename "$wallpaper" >"$CURRENT_FILE"
}

main() {
  if [ -n "$1" ]; then
    apply_wallpaper "$1" || exit 1
  fi
}

main "$@"
