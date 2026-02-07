#!/bin/bash

# Switch to next keyboard layout
niri msg action switch-layout next

# Get current keyboard layout (the one with the asterisk)
layMain=$(niri msg keyboard-layouts | grep '^ \*' | sed 's/^ \* [0-9]* //')

ICONS_DIR="${XDG_CONFIG_HOME}/mako/icons"
# Send notification
notify-send -a "keyboard" -t 800 -i "${ICONS_DIR}/keyboard.svg" "${layMain}"
