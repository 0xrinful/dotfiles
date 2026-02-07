#!/bin/bash

if pkill -x rofi; then
  exit 0
fi

SELECTED_ITEM=$(cliphist list | rofi -dmenu -theme cliphist)

if [ -z "$SELECTED_ITEM" ]; then
  exit 0
fi

cliphist decode <<<"$SELECTED_ITEM" | wl-copy
