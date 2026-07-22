#!/usr/bin/env zsh
# claude_agents — center indicator; custom widget (unchanged)

sketchybar --add item claude_agents center \
    --set claude_agents \
    icon=󰚩 \
    icon.font="$ICON_FONT:Bold:16.0" \
    icon.color=$BG_OVERLAY \
    icon.padding_right=4 \
    label="zzz" \
    label.color=$FG_DIM \
    background.color=$BG_TRANSPARENT \
    background.padding_right=0 \
    update_freq=5 \
    script="$PLUGIN_DIR/claude_agents.sh"

for i in $(seq 1 5); do
    sketchybar --add item claude_agent_$i center \
        --set claude_agent_$i \
        icon=󰚩 \
        icon.font="$ICON_FONT:Bold:16.0" \
        icon.drawing=off \
        icon.padding_left=4 \
        icon.padding_right=2 \
        label.drawing=off \
        background.color=$BG_TRANSPARENT \
        background.padding_left=0 \
        background.padding_right=0
done
