#!/usr/bin/env bash

# Configuration
ICONS_DIR="${XDG_CONFIG_HOME}/mako/icons"
step=5

print_usage() {
  cat <<EOF
Usage: $(basename "$0") -[device] <action> [step]

Devices:
    -i    Input device (microphone)
    -o    Output device (speaker)

Actions:
    i     Increase volume
    d     Decrease volume
    m     Toggle mute

Examples:
    $(basename "$0") -o i 5   # Increase output volume by 5
    $(basename "$0") -i d 10  # Decrease input volume by 10
    $(basename "$0") -o m     # Toggle output mute
EOF
  exit 1
}

# Notifications
notify_vol() {
  local vol=$1
  angle=$((((vol + 2) / 5) * 5))
  [ "$angle" -gt 100 ] && angle=100
  icon="${ICONS_DIR}/media/knob-${angle}.svg"
  bar=$(seq -s "." $((vol / 20)) | sed 's/[0-9]//g')
  notify-send -a "volume" -t 800 -i "${icon}" "${vol}${bar}" "${nsink}"
}

notify_mute() {
  mute=$(pamixer "${srce}" --get-mute)
  [ "${srce}" == "--default-source" ] && dvce="microphone" || dvce="speaker"

  if [ "${mute}" == "true" ]; then
    notify-send -a "volume" -t 800 -i "${ICONS_DIR}/media/muted-${dvce}.svg" "muted" "${nsink}"
  else
    notify-send -a "volume" -t 800 -i "${ICONS_DIR}/media/unmuted-${dvce}.svg" "unmuted" "${nsink}"
  fi
}

# Volume Controls
change_volume() {
  local action=$1
  local step=$2
  pamixer "${srce}" -"${action}" "${step}"
  vol=$(pamixer "${srce}" --get-volume)
  notify_vol "$vol"
}

toggle_mute() {
  pamixer "${srce}" -t
  notify_mute
}

# Main
while getopts "io" opt; do
  case $opt in
  i)
    srce="--default-source"
    nsink=$(pamixer --list-sources | awk -F '"' 'END {print $(NF - 1)}')
    ;;
  o)
    srce=""
    nsink=$(pamixer --get-default-sink | awk -F '"' 'END{print $(NF - 1)}')
    ;;
  *)
    print_usage
    ;;
  esac
done

shift $((OPTIND - 1))

# Validate arguments
[ $OPTIND -eq 1 ] && print_usage
[ -z "$1" ] && print_usage

# Execute action
case $1 in
i | d) change_volume "$1" "${2:-$step}" ;;
m) toggle_mute ;;
*) print_usage ;;
esac
