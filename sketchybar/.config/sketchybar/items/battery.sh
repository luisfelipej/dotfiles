#!/usr/bin/env zsh
# battery — right; laptop-only (sourced conditionally by rc)

sketchybar --add item battery right \
    --set battery \
    icon.color=$BATTERY_OK \
    label.color=$FG \
    update_freq=20 \
    script="$PLUGIN_DIR/battery.sh"
