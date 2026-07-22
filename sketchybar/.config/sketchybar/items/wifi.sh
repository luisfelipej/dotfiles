#!/usr/bin/env zsh
# wifi — right; timer-polled + click-to-toggle label

sketchybar --add item wifi right \
    --set wifi \
    icon="󰖩" \
    label.width=dynamic \
    padding_right=7 \
    update_freq=10 \
    script="$PLUGIN_DIR/wifi.sh" \
    --subscribe wifi mouse.clicked
