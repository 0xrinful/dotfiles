#!/usr/bin/env bash

# Configuration
ICONS_DIR="${XDG_CONFIG_HOME}/mako/icons"
HIGH_THRESHOLD=85 # Notify when battery reaches this percentage while charging
LOW_THRESHOLD=10  # Notify when battery drops to this percentage while discharging
INTERVAL=5        # Only notify every X% change to avoid spam

# Check if system has a battery
is_laptop() {
  if grep -q "Battery" /sys/class/power_supply/BAT*/type 2>/dev/null; then
    return 0
  else
    echo "No battery detected."
    exit 0
  fi
}

is_laptop

# Get current battery information
get_battery_info() {
  local total_percentage=0
  local battery_count=0

  for battery in /sys/class/power_supply/BAT*; do
    battery_status=$(<"$battery/status")
    local capacity=$(<"$battery/capacity")
    total_percentage=$((total_percentage + capacity))
    battery_count=$((battery_count + 1))
  done

  battery_percentage=$((total_percentage / battery_count))
}

# Send notifications based on battery status
notify_battery_status() {
  local status=$1
  local percentage=$2

  case "$status" in
  "Discharging")
    if [[ "$prev_status" != "Discharging" ]]; then
      notify-send -a "Battery Monitor" -u normal -i "${ICONS_DIR}/battery-discharging.svg" "Charger Unplugged" "Battery is at ${percentage}%"
      prev_status="Discharging"
    fi

    # Low battery warning
    if [[ $percentage -le $LOW_THRESHOLD ]] && [[ $((last_notified - percentage)) -ge $INTERVAL || $last_notified -eq -1 ]]; then
      notify-send -a "Battery Monitor" -u critical -t 0 -i "${ICONS_DIR}/battery-alert.svg" "Battery Low" "Battery is at ${percentage}%. Please plug in the charger."
      last_notified=$percentage
    fi
    ;;

  "Charging" | "Not charging")
    if [[ "$is_first_run" == "true" ]]; then
      prev_status="Charging"
    else
      if [[ "$prev_status" == "Discharging" ]]; then
        makoctl dismiss -a

        notify-send -a "Battery Monitor" -u normal -i "${ICONS_DIR}/battery-charging.svg" "Charger Plugged In" "Battery is at ${percentage}%"
        prev_status="Charging"
      # High battery notification
      elif [[ $percentage -ge $HIGH_THRESHOLD ]] && [[ $((percentage - last_notified)) -ge $INTERVAL || $last_notified -eq -1 ]]; then
        notify-send -a "Battery Monitor" -u normal -i "${ICONS_DIR}/battery-charging.svg" "Battery Charged" "Battery is at ${percentage}%. You can unplug the charger."
        last_notified=$percentage
      fi
    fi
    ;;

  "Full")
    if [[ "$prev_status" != "Full" ]]; then
      notify-send -a "Battery Monitor" -u normal -i "${ICONS_DIR}/battery.svg" "Battery Full" "Battery is fully charged. You can unplug the charger."
      prev_status="Full"
    fi
    ;;
  esac
}

# Monitor battery status changes
monitor_battery() {
  get_battery_info
  last_notified=-1
  prev_status=$battery_status
  is_first_run=true

  echo "Battery monitor started..."
  echo "Will notify at ${LOW_THRESHOLD}% (low) and ${HIGH_THRESHOLD}% (high)"

  # Monitor using dbus
  dbus-monitor --system "type='signal',interface='org.freedesktop.DBus.Properties',path='$(upower -e | grep battery)'" 2>/dev/null |
    while read -r line; do
      get_battery_info
      if [ "$battery_status" != "$last_status" ] || [ "$battery_percentage" != "$last_percentage" ]; then
        notify_battery_status "$battery_status" "$battery_percentage"
        is_first_run=false
        last_status=$battery_status
        last_percentage=$battery_percentage
      fi
    done
}

# Start monitoring
monitor_battery
