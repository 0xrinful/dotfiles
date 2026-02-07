#!/bin/bash

set -e # Exit on error

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Helper functions
print_info() {
  echo -e "${BLUE}[INFO]${NC} $1"
}

print_success() {
  echo -e "${GREEN}[SUCCESS]${NC} $1"
}

print_warning() {
  echo -e "${YELLOW}[WARNING]${NC} $1"
}

print_error() {
  echo -e "${RED}[ERROR]${NC} $1"
}

# Check if script is run as root
if [[ $EUID -eq 0 ]]; then
  print_error "This script should NOT be run as root (don't use sudo)"
  print_info "The script will ask for sudo password when needed"
  exit 1
fi

# Get the directory where the script is located
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CONFIG_DIR="$SCRIPT_DIR/config"

print_info "Rice installation starting..."
print_info "Script directory: $SCRIPT_DIR"

# Step 1: Install packages
print_info "Installing packages from packages.txt..."

if [[ ! -f "$SCRIPT_DIR/packages.txt" ]]; then
  print_error "packages.txt not found in $SCRIPT_DIR"
  exit 1
fi

# Detect package manager
if command -v paru &>/dev/null; then
  PKG_MANAGER="paru"
elif command -v yay &>/dev/null; then
  PKG_MANAGER="yay"
elif command -v pacman &>/dev/null; then
  PKG_MANAGER="sudo pacman"
else
  print_error "No supported package manager found (pacman/yay/paru)"
  exit 1
fi

print_info "Using package manager: $PKG_MANAGER"

# Read packages and install
mapfile -t packages <"$SCRIPT_DIR/packages.txt"
packages_clean=()

for pkg in "${packages[@]}"; do
  # Remove comments and trim whitespace
  pkg=$(echo "$pkg" | sed 's/#.*//' | xargs)
  # Skip empty lines
  [[ -z "$pkg" ]] && continue
  packages_clean+=("$pkg")
done

if [[ ${#packages_clean[@]} -gt 0 ]]; then
  print_info "Installing ${#packages_clean[@]} packages..."
  if [[ "$PKG_MANAGER" == "sudo pacman" ]]; then
    sudo pacman -S --needed --noconfirm "${packages_clean[@]}" || print_warning "Some packages may have failed to install"
  else
    $PKG_MANAGER -S --needed --noconfirm "${packages_clean[@]}" || print_warning "Some packages may have failed to install"
  fi
  print_success "Package installation completed"
else
  print_warning "No packages found in packages.txt"
fi

# Step 2: Backup existing configs
print_info "Creating backups of existing configurations..."

BACKUP_DIR="$HOME/.rice-backup-$(date +%Y%m%d-%H%M%S)"
mkdir -p "$BACKUP_DIR"

# Backup existing .config directories
if [[ -d "$HOME/.config" ]]; then
  for dir in "$CONFIG_DIR/.config"/*; do
    if [[ -d "$dir" ]]; then
      dirname=$(basename "$dir")
      if [[ -d "$HOME/.config/$dirname" ]]; then
        print_info "Backing up ~/.config/$dirname"
        mv "$HOME/.config/$dirname" "$BACKUP_DIR/"
      fi
    fi
  done
fi

# Backup existing .local directories
if [[ -d "$HOME/.local" ]]; then
  for item in share bin; do
    if [[ -d "$HOME/.local/$item" ]]; then
      print_info "Backing up ~/.local/$item"
      mkdir -p "$BACKUP_DIR/.local"
      cp -r "$HOME/.local/$item" "$BACKUP_DIR/.local/"
    fi
  done
fi

# Backup dotfiles
for file in .gtkrc-2.0 .zshenv; do
  if [[ -f "$HOME/$file" ]]; then
    print_info "Backing up ~/$file"
    cp "$HOME/$file" "$BACKUP_DIR/"
  fi
done

print_success "Backups created in $BACKUP_DIR"

# Step 3: Copy configuration files
print_info "Copying configuration files..."

# Create necessary directories
mkdir -p "$HOME/.config"
mkdir -p "$HOME/.local/bin"
mkdir -p "$HOME/.local/share"

# Copy .config directories
if [[ -d "$CONFIG_DIR/.config" ]]; then
  print_info "Copying .config directories..."
  cp -r "$CONFIG_DIR/.config"/* "$HOME/.config/"
  print_success ".config directories copied"
fi

# Copy .local/bin scripts
if [[ -d "$CONFIG_DIR/.local/bin" ]]; then
  print_info "Copying bin scripts..."
  cp -r "$CONFIG_DIR/.local/bin"/* "$HOME/.local/bin/"
  print_success "Bin scripts copied"
fi

# Copy .local/share (fonts, themes, icons, etc.)
if [[ -d "$CONFIG_DIR/.local/share" ]]; then
  print_info "Copying local share files (fonts, themes, icons)..."
  cp -r "$CONFIG_DIR/.local/share"/* "$HOME/.local/share/"
  print_success "Local share files copied"
fi

# Copy individual config files in .config root
for file in "$CONFIG_DIR/.config"/*; do
  if [[ -f "$file" ]]; then
    filename=$(basename "$file")
    print_info "Copying .config/$filename..."
    cp "$file" "$HOME/.config/"
  fi
done

# Copy dotfiles
if [[ -f "$CONFIG_DIR/.gtkrc-2.0" ]]; then
  print_info "Copying .gtkrc-2.0..."
  cp "$CONFIG_DIR/.gtkrc-2.0" "$HOME/"
fi

if [[ -f "$CONFIG_DIR/.zshenv" ]]; then
  print_info "Copying .zshenv..."
  cp "$CONFIG_DIR/.zshenv" "$HOME/"
fi

print_success "All configuration files copied"

# Step 4: Set executable permissions for scripts
print_info "Setting executable permissions for scripts in ~/.local/bin..."

if [[ -d "$HOME/.local/bin" ]]; then
  chmod +x "$HOME/.local/bin"/*.sh 2>/dev/null || true
  # Also handle scripts without .sh extension
  find "$HOME/.local/bin" -type f -exec chmod +x {} \;
  print_success "Executable permissions set"
else
  print_warning "~/.local/bin directory not found"
fi

# Step 5: Update font cache
if command -v fc-cache &>/dev/null; then
  print_info "Updating font cache..."
  fc-cache -fv
  print_success "Font cache updated"
fi

# Step 6: Change shell to zsh
print_info "Changing default shell to zsh..."

if command -v zsh &>/dev/null; then
  current_shell=$(basename "$SHELL")
  if [[ "$current_shell" != "zsh" ]]; then
    print_info "Current shell: $current_shell"
    chsh -s "$(which zsh)"
    print_success "Default shell changed to zsh (will take effect on next login)"
  else
    print_info "Shell is already set to zsh"
  fi
else
  print_error "zsh is not installed!"
  exit 1
fi

# Step 7: Enable systemd user services
print_info "Enabling systemd user services..."

# Add service dependencies to niri.service
if systemctl --user list-unit-files niri.service &>/dev/null; then
  print_info "Adding waybar.service to niri.service wants..."
  systemctl --user add-wants niri.service waybar.service 2>/dev/null || print_warning "Failed to add waybar.service dependency"

  print_info "Adding mako.service to niri.service wants..."
  systemctl --user add-wants niri.service mako.service 2>/dev/null || print_warning "Failed to add mako.service dependency"
else
  print_warning "niri.service not found, skipping service dependencies"
fi

# Enable and start polkit-gnome service
if systemctl --user list-unit-files polkit-gnome.service &>/dev/null; then
  print_info "Enabling polkit-gnome.service..."
  systemctl --user enable --now polkit-gnome.service
  print_success "polkit-gnome.service enabled and started"
else
  print_warning "polkit-gnome.service not found"
fi

# Step 8: Final information
echo ""
print_success "╔════════════════════════════════════════════════════════════╗"
print_success "║          Rice installation completed successfully!        ║"
print_success "╚════════════════════════════════════════════════════════════╝"
echo ""
print_info "Next steps:"
echo "  1. Reboot (recommended) or log out and log back in"
echo "  2. Open a terminal using Mod+Q"
echo "  3. Run 'init.sh' (one time only per install) to initialize settings"
echo "  4. Done. Enjoy the rice."
echo "  Your old configs have been backed up to: $BACKUP_DIR"
echo ""
