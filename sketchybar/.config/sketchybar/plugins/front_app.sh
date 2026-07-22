#!/usr/bin/env bash
# front_app — set app glyph via icon_map.sh + name, on front_app_switched

if [ "$SENDER" = "front_app_switched" ]; then
  sketchybar --set "$NAME" \
    label="$INFO" \
    icon="$("$CONFIG_DIR/icon_map.sh" "$INFO")"
fi
