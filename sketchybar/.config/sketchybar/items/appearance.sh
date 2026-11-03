#!/usr/bin/env zsh
# appearance — hidden; listens for macOS light/dark switches and runs
# plugins/appearance.sh, which recolors the bar and the window borders

sketchybar --add event appearance_changed AppleInterfaceThemeChangedNotification \
    --add item appearance left \
    --set appearance \
    drawing=off \
    updates=on \
    script="$PLUGIN_DIR/appearance.sh" \
    --subscribe appearance appearance_changed
