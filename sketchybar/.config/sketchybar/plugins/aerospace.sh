#!/usr/bin/env zsh

source "$HOME/.config/sketchybar/colors.sh"

# Highlight the current aerospace workspace
if [ "$1" = "$FOCUSED_WORKSPACE" ]; then
    sketchybar --set $NAME background.color=$SPACE_ACTIVE icon.color=$BAR_COLOR label.color=$BAR_COLOR
else
    sketchybar --set $NAME background.color=$BG_PRIMARY icon.color=$FG_MUTED label.color=$FG_MUTED
fi
