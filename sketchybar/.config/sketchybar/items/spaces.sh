#!/usr/bin/env zsh
# spaces — AeroSpace workspaces 1..9; aerospace.sh plugin on workspace change

sketchybar --add event aerospace_workspace_change

for sid in $(seq 1 9); do
    sketchybar --add item space.$sid left \
        --set space.$sid \
        background.color=$BG_PRIMARY \
        background.corner_radius=4 \
        background.height=24 \
        icon=$sid \
        icon.color=$FG_MUTED \
        icon.font="$LABEL_FONT:Bold:13.0" \
        icon.padding_left=8 \
        icon.padding_right=8 \
        label.drawing=off \
        click_script="aerospace workspace $sid" \
        script="$PLUGIN_DIR/aerospace.sh $sid" \
        --subscribe space.$sid aerospace_workspace_change
done
