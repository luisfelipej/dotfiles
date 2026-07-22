#!/usr/bin/env zsh

source "$HOME/.config/sketchybar/colors.sh"

# Highlight the focused AeroSpace workspace as a filled rounded pill;
# mute inactive workspaces (transparent background, dim icon).
if [ "$1" = "$FOCUSED_WORKSPACE" ]; then
    sketchybar --set $NAME \
        background.drawing=on \
        background.color=$SPACE_ACTIVE \
        icon.color=$BAR_COLOR
else
    sketchybar --set $NAME \
        background.drawing=on \
        background.color=$BG_PRIMARY \
        icon.color=$FG_MUTED
fi
