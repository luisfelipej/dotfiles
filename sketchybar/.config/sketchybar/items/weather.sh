#!/usr/bin/env zsh
# weather — right; plugins/weather_minimal.sh, refresh 30m + on wake

sketchybar --add item weather right \
    --set weather \
    icon.color=$WEATHER_FG \
    update_freq=1800 \
    script="$PLUGIN_DIR/weather_minimal.sh" \
    --subscribe weather system_woke
