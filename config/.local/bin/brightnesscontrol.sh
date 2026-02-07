#!/usr/bin/env bash

# Configuration
ICONS_DIR="${XDG_CONFIG_HOME}/mako/icons"
step=5

print_usage() {
  cat <<EOF
Usage: $(basename "$0") <action> [step]

Actions:
    i     Increase brightness
    d     Decrease brightness

Optional:
    step  Brightness change step (default: 5)

Examples:
    $(basename "$0") i 10    # Increase brightness by 10%
    $(basename "$0") d       # Decrease brightness by 5%
EOF
  exit 1
}

send_notification() {
  brightness=$(brightnessctl info | grep -oP "(?<=\()\d+(?=%)")
  brightinfo=$(brightnessctl info | awk -F "'" '/Device/ {print $2}')
  angle="$((((brightness + 2) / 5) * 5))"

  icon="${ICONS_DIR}/media/knob-${angle}.svg"
  bar=$(seq -s "." $((brightness / 20)) | sed 's/[0-9]//g')
  notify-send -a "brightness" -t 800 -i "${icon}" "${brightness}${bar}" "${brightinfo}"
}

get_brightness() {
  brightnessctl -m | grep -o '[0-9]\+%' | head -c-2
}

# Validate arguments
[ -z "$1" ] && print_usage

step="${2:-$step}"

case $1 in
i)
  if [[ $(get_brightness) -lt 10 ]]; then
    step=1
  fi
  brightnessctl set +"${step}"%
  send_notification
  ;;
d)
  if [[ $(get_brightness) -le 10 ]]; then
    step=1
  fi
  if [[ $(get_brightness) -le 1 ]]; then
    brightnessctl set "${step}"%
  else
    brightnessctl set "${step}"%-
  fi
  send_notification
  ;;
*)
  print_usage
  ;;
esac
