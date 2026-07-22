#!/usr/bin/env zsh
# pomodoro — right; plugins/pomodoro.sh, click to toggle

sketchybar --add item pomodoro right \
    --set pomodoro \
    icon=󰔟 \
    icon.color=$POMODORO_FG \
    label="off" \
    update_freq=1 \
    script="$PLUGIN_DIR/pomodoro.sh" \
    --subscribe pomodoro mouse.clicked
