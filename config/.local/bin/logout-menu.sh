#!/bin/bash

if pkill -x wlogout; then
  exit 0
fi

layout="${XDG_CONFIG_HOME}/wlogout/layout"
layoutStyle="${XDG_CONFIG_HOME}/wlogout/style.css"

wlogout -b 6 -c 0 -r 0 -m 0 --layout "$layout" --css "$layoutStyle" --protocol layer-shell
