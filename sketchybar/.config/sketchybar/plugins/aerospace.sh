#!/usr/bin/env bash
# aerospace — for one workspace pill ($1 = its id): highlight it if focused and
# show glyphs of the apps living in it. Runs on aerospace_workspace_change,
# front_app_switched, and mouse.clicked.

source "$CONFIG_DIR/colors.sh"

SID="$1"

# FOCUSED_WORKSPACE is supplied by the aerospace_workspace_change trigger; other
# events (front_app_switched, mouse.clicked) don't carry it — resolve it then.
FOCUSED="${FOCUSED_WORKSPACE:-$(aerospace list-workspaces --focused 2>/dev/null)}"

# Build the app-glyph strip for this workspace: unique app names -> :ligatures:
# rendered by sketchybar-app-font (same icon_map the front_app widget uses).
apps=$(aerospace list-windows --workspace "$SID" --format '%{app-name}' 2>/dev/null | sort -u)
icon_strip=""
while IFS= read -r app; do
    [ -z "$app" ] && continue
    icon_strip+="$("$CONFIG_DIR/icon_map.sh" "$app")"
done <<< "$apps"

# Highlight the focused pill; mute the rest.
if [ "$SID" = "$FOCUSED" ]; then
    sketchybar --set "$NAME" background.drawing=on background.color="$SPACE_ACTIVE" \
        icon.color="$BAR_COLOR" label.color="$BAR_COLOR"
else
    sketchybar --set "$NAME" background.drawing=on background.color="$BG_PRIMARY" \
        icon.color="$FG_MUTED" label.color="$FG_MUTED"
fi

# Show the app glyphs, or hide the label on an empty workspace.
if [ -n "$icon_strip" ]; then
    sketchybar --set "$NAME" label="$icon_strip" label.drawing=on
else
    sketchybar --set "$NAME" label.drawing=off
fi
