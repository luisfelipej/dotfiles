#!/usr/bin/env zsh
# brightness — right; timer-polled (15s)

sketchybar --add item brightness right \
    --set brightness \
    update_freq=15 \
    script="$PLUGIN_DIR/brightness.sh"
