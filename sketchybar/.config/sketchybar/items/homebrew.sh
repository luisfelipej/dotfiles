#!/usr/bin/env zsh
# homebrew — right; outdated count + click popup; 5m timer

POPUP_CLICK='sketchybar --set $NAME popup.drawing=toggle'

sketchybar --add event brew_update

sketchybar --add item homebrew right \
    --set homebrew \
    icon= \
    label="?" \
    update_freq=300 \
    popup.height=30 \
    popup.background.color=$POPUP_BG \
    popup.background.border_color=$POPUP_BORDER \
    popup.background.border_width=2 \
    popup.background.corner_radius=6 \
    click_script="$POPUP_CLICK" \
    script="$PLUGIN_DIR/homebrew.sh" \
    --subscribe homebrew mouse.clicked brew_update
