#!/usr/bin/env zsh
# clock — right; plugins/clock.sh on 10s timer

sketchybar --add item clock right \
    --set clock \
    icon=󰃰 \
    icon.color=$CLOCK_FG \
    update_freq=10 \
    script="$PLUGIN_DIR/clock.sh"
