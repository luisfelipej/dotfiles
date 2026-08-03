#!/usr/bin/env bash
# wifi — SSID / disconnected; timer-polled. Click toggles label width.
# SSID read per https://snelson.us/2024/09/determining-a-macs-ssid-like-an-animal/

source "$CONFIG_DIR/colors.sh"

ICON_DISCONNECTED="󰖪"
ICON_CONNECTED="󰖩"

update() {
  local wifi_port ssid
  wifi_port=$(networksetup -listallhardwareports | awk '/Hardware Port: Wi-Fi/{getline; print $2}')
  ssid=$(ipconfig getsummary "$wifi_port" 2>/dev/null | awk -F ' SSID : ' '/ SSID : / {print $2}')

  if [ -z "$ssid" ]; then
    sketchybar --set "$NAME" icon="$ICON_DISCONNECTED" label="Disconnected" \
      icon.color="$WIFI_OFF" label.color="$WIFI_OFF"
  else
    sketchybar --set "$NAME" icon="$ICON_CONNECTED" label="$ssid" \
      icon.color="$WIFI_OK" label.color="$WIFI_OK"
  fi
}

click() {
  local current_width
  current_width=$(sketchybar --query "$NAME" | jq -r .label.width)
  local width=0
  [ "$current_width" -eq 0 ] && width=dynamic
  sketchybar --animate sin 20 --set "$NAME" label.width="$width"
}

case "$SENDER" in
  "mouse.clicked") click ;;
  *) update ;;
esac
