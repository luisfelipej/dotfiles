#!/usr/bin/env zsh
# apple — logo with popup: Settings, Activity Monitor, Lock

POPUP_OFF='sketchybar --set apple.logo popup.drawing=off'
POPUP_CLICK='sketchybar --set $NAME popup.drawing=toggle'

apple_logo=(
  icon=""
  icon.font="$ICON_FONT:Bold:16.0"
  icon.color=$FG
  icon.padding_left=8
  icon.padding_right=8
  label.drawing=off
  background.drawing=off
  popup.height=32
  popup.background.color=$POPUP_BG
  popup.background.border_color=$POPUP_BORDER
  popup.background.border_width=2
  popup.background.corner_radius=6
  click_script="$POPUP_CLICK"
)

apple_prefs=(
  icon=""
  label="Settings"
  click_script="open -a 'System Settings'; $POPUP_OFF"
)
apple_activity=(
  icon="󱎴"
  label="Activity Monitor"
  click_script="open -a 'Activity Monitor'; $POPUP_OFF"
)
apple_lock=(
  icon=""
  label="Lock Screen"
  click_script="pmset displaysleepnow; $POPUP_OFF"
)

sketchybar --add item apple.logo left \
  --set apple.logo "${apple_logo[@]}" \
  --add item apple.prefs popup.apple.logo \
  --set apple.prefs "${apple_prefs[@]}" \
  --add item apple.activity popup.apple.logo \
  --set apple.activity "${apple_activity[@]}" \
  --add item apple.lock popup.apple.logo \
  --set apple.lock "${apple_lock[@]}"
