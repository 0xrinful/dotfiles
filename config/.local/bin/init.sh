#!/usr/bin/env bash
#===============================================================================
# Initialization Script
# Sets up symlinks, and generates wallpaper assets (thumbnails + colors)
#===============================================================================

set -euo pipefail

### Directories & Settings
WALLPAPER_DIR="$HOME/.config/swww/wallpapers"
COLORS_DIR="$HOME/.config/swww/colors"
CACHE_DIR="$HOME/.cache/wallpaper-selector"
THUMB_SIZE="500x400"

#-------------------------------
# GNOME / GTK theme settings
#-------------------------------
echo "🎨 Applying GTK theme..."
ln -sf "$HOME/.local/share/themes/Wallbash-Gtk/gtk-4.0" "$HOME/.config/gtk-4.0"

gsettings set org.gnome.desktop.interface gtk-theme 'Wallbash-Gtk'
gsettings set org.gnome.desktop.interface icon-theme 'Tela-circle-dracula'
gsettings set org.gnome.desktop.interface color-scheme 'prefer-dark'
gsettings set org.gnome.desktop.interface cursor-theme 'Bibata-Modern-Ice'
gsettings set org.gnome.desktop.interface cursor-size 20
gsettings set org.gnome.desktop.interface font-name 'Cantarell 12'
gsettings set org.gnome.desktop.interface document-font-name 'Cantarell 12'
gsettings set org.gnome.desktop.interface monospace-font-name 'CaskaydiaCove Nerd Font Mono 10'
gsettings set org.gnome.desktop.interface font-antialiasing 'rgba'
gsettings set org.gnome.desktop.interface font-hinting 'full'
gsettings set org.gnome.desktop.interface text-scaling-factor 1.05
gsettings set org.gnome.desktop.wm.preferences button-layout ''

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
set-wallpaper.sh random
echo "✨ Initialization complete!"
