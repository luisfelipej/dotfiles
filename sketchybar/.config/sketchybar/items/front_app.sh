#!/usr/bin/env zsh
# front_app — focused app glyph (sketchybar-app-font) + name

sketchybar --add item front_app left \
    --set front_app \
    background.color=$BG_TRANSPARENT \
    icon.color=$FG \
    icon.font="sketchybar-app-font:Regular:16.0" \
    icon.padding_left=8 \
    icon.padding_right=6 \
    label.color=$FG \
    label.font="$LABEL_FONT:Bold:13.0" \
    script="$PLUGIN_DIR/front_app.sh" \
    --subscribe front_app front_app_switched
