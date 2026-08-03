#!/usr/bin/env zsh
# spaces — AeroSpace workspaces 1..9. Each pill shows the number (icon, in the
# label font) plus glyphs of the apps living in that space (label, in
# sketchybar-app-font). aerospace.sh highlights the focused space and builds the
# app-glyph strip; it refreshes on workspace change and on app focus change.

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
        icon.padding_right=4 \
        label.font="sketchybar-app-font:Regular:13.0" \
        label.color=$FG_MUTED \
        label.padding_left=0 \
        label.padding_right=8 \
        label.drawing=off \
        click_script="aerospace workspace $sid" \
        script="$PLUGIN_DIR/aerospace.sh $sid" \
        --subscribe space.$sid aerospace_workspace_change front_app_switched
done
