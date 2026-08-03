#!/usr/bin/env bash
# brightness — screen brightness %, timer-polled via the `brightness` CLI

source "$CONFIG_DIR/colors.sh"

# brightness -l prints e.g. "display 0: brightness 0.849998"; take the first display.
FRAC=$(/opt/homebrew/bin/brightness -l 2>/dev/null | awk '/brightness/ {print $NF; exit}')
if [ -z "$FRAC" ]; then
  sketchybar --set "$NAME" drawing=off
  exit 0
fi
PCT=$(awk -v f="$FRAC" 'BEGIN {printf "%.0f", f * 100}')

if [ "$PCT" -ge 70 ]; then ICON="󰃠"
elif [ "$PCT" -ge 30 ]; then ICON="󰃝"
elif [ "$PCT" -ge 1 ]; then ICON="󰃟"
else ICON="󰃞"; fi

sketchybar --set "$NAME" \
  drawing=on \
  icon="$ICON" \
  label="${PCT}%" \
  icon.color="$BRIGHTNESS_FG" \
  label.color="$BRIGHTNESS_FG"
