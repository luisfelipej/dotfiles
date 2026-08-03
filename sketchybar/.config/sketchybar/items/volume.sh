#!/usr/bin/env zsh
# volume — right; plugins/volume.sh on volume_change

sketchybar --add item volume right \
    --set volume \
    icon.color=$VOLUME_FG \
    label.drawing=true \
    script="$PLUGIN_DIR/volume.sh" \
    --subscribe volume volume_change
