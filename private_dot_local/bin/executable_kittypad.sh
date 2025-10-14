#!/bin/bash

# Set Kitty padding to 0 before entering Neovim
kitty @ set-spacing padding=5 margin=0
kitty @ set-font-size 12

# Launch Command
"$@"

# Set Kitty padding to 25 after exiting Neovim
kitty @ set-spacing padding=25 margin=0
[ "$KITTY_WINDOW_ID" = 1 ] && kitty @ set-font-size 11.5
