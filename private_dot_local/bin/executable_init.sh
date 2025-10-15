#!/usr/bin/env bash
#===============================================================================
# Initialization Script
# Sets up services, symlinks, and generates wallpaper assets (thumbnails + colors)
#===============================================================================

set -euo pipefail

### Directories & Settings
WALLPAPER_DIR="$HOME/.config/swww/wallpapers"
COLORS_DIR="$HOME/.config/swww/colors"
CACHE_DIR="$HOME/.cache/wallpaper-selector"
THUMB_SIZE="500x400"

### Services
echo "🔧 Linking user services..."
# systemctl --user add-wants niri.service waybar.service
# systemctl --user add-wants niri.service mako.service
# systemctl --user enable --now polkit-gnome.service

### GTK Symlink
echo "🎨 Applying GTK theme..."
# ln -sf "$HOME/.local/share/themes/Wallbash-Gtk/gtk-4.0" "$HOME/.config/gtk-4.0"

### Ensure directories exist
mkdir -p "$COLORS_DIR" "$HOME/.config/mako/icons/media" "$HOME/.config/Kvantum/wallbash"
mkdir -p "$CACHE_DIR" "$HOME/.cache/wal"

### Generate wallpapers assets
generate_wall_assets() {
  echo "🖼️  Generating wallpaper assets..."
  local count=0

  for img in "$WALLPAPER_DIR"/*.{jpg,jpeg,png,webp}; do
    [ -f "$img" ] || continue

    local wall_name="${img##*/}"
    wall_name="${wall_name%.*}"
    local colors="$COLORS_DIR/$wall_name.dcol"
    local thumb="$CACHE_DIR/$wall_name.png"

    if [ ! -f "$colors" ]; then
      echo "🎨 Generating color template for: $wall_name"
      wallbash.sh "$img" "$COLORS_DIR/$wall_name"
    fi

    if [ ! -f "$thumb" ] || [ "$img" -nt "$thumb" ]; then
      echo "🧩 Creating thumbnail for: $wall_name"
      convert "$img" -resize "$THUMB_SIZE^" -gravity center -extent "$THUMB_SIZE" "$thumb" 2>/dev/null || {
        echo "⚠️  Failed to generate thumbnail for: $wall_name"
      }
    fi

    count=$((count + 1))
  done

  if ((count == 0)); then
    echo "⚠️  No wallpapers found in $WALLPAPER_DIR"
  else
    echo "✅ Generated assets for $count wallpapers."
  fi
}

generate_wall_assets
echo "✨ Initialization complete!"
