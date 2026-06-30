#!/usr/bin/env zsh

source "$HOME/.config/sketchybar/colors.sh"

MAX_ICONS=5

# Count active claude processes (exclude grep and helper processes)
AGENT_COUNT=$(ps aux | grep -E "[c]laude" | grep -v "grep\|helper\|Helper" | wc -l | tr -d ' ')

# Determine color based on count — Gruvbox Material ramp
if [[ $AGENT_COUNT -eq 0 ]]; then
    COLOR=$BG_OVERLAY
elif [[ $AGENT_COUNT -eq 1 ]]; then
    COLOR=$FG
elif [[ $AGENT_COUNT -eq 2 ]]; then
    COLOR=$GREEN
elif [[ $AGENT_COUNT -eq 3 ]]; then
    COLOR=$YELLOW
else
    COLOR=$ORANGE
fi

# Update main item
if [[ $AGENT_COUNT -eq 0 ]]; then
    sketchybar --set claude_agents icon=󰚩 icon.color=$COLOR label="zzz" label.color=$FG_DIM label.drawing=yes
else
    sketchybar --set claude_agents icon=󰚩 icon.color=$COLOR label.drawing=no
fi

# Update follower icons (show/hide based on count)
for i in $(seq 1 $MAX_ICONS); do
    if [[ $i -lt $AGENT_COUNT && $i -lt $MAX_ICONS ]]; then
        sketchybar --set claude_agent_$i icon.drawing=on icon.color=$COLOR
    elif [[ $i -eq $MAX_ICONS && $AGENT_COUNT -gt $MAX_ICONS ]]; then
        sketchybar --set claude_agent_$i icon.drawing=on icon.color=$COLOR icon="+$((AGENT_COUNT - MAX_ICONS))"
    else
        sketchybar --set claude_agent_$i icon.drawing=off
    fi
done
