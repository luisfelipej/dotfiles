#!/usr/bin/env zsh
# front_app — focused app: accent icon block + separator + name (current design)

sketchybar --add item front_app left \
    --set front_app \
    background.color=$ACCENT \
    background.padding_left=0 \
    background.padding_right=0 \
    icon.y_offset=0 \
    icon.color=$BAR_COLOR \
    label.drawing=no \
    script="$PLUGIN_DIR/front_app.sh" \
    --add item front_app.separator left \
    --set front_app.separator \
    background.color=$BG_TRANSPARENT \
    background.padding_left=0 \
    icon= \
    icon.color=$ACCENT \
    icon.font="$ICON_FONT:Bold:18.0" \
    icon.padding_left=0 \
    icon.padding_right=0 \
    icon.y_offset=0 \
    label.drawing=no \
    --add item front_app.name left \
    --set front_app.name \
    background.color=$BG_TRANSPARENT \
    background.padding_right=0 \
    icon.drawing=off \
    label.font="$LABEL_FONT:Bold:13.0" \
    label.color=$FG \
    label.drawing=yes

sketchybar --add bracket front_app_bracket \
    front_app \
    front_app.separator \
    front_app.name \
    --subscribe front_app front_app_switched
