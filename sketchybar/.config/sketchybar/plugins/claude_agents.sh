#!/usr/bin/env zsh

MAX_ICONS=5

# Count active claude processes (exclude grep and helper processes)
AGENT_COUNT=$(ps aux | grep -E "[c]laude" | grep -v "grep\|helper\|Helper" | wc -l | tr -d ' ')

# Determine color based on count
if [[ $AGENT_COUNT -eq 0 ]]; then
    COLOR="0x66313244"
elif [[ $AGENT_COUNT -eq 1 ]]; then
    COLOR="0xffcdd6f4"
elif [[ $AGENT_COUNT -eq 2 ]]; then
    COLOR="0xffa6e3a1"
elif [[ $AGENT_COUNT -eq 3 ]]; then
    COLOR="0xfff9e2af"
else
    COLOR="0xfffab387"
fi

# Update main item
if [[ $AGENT_COUNT -eq 0 ]]; then
    sketchybar --set claude_agents icon=󰚩 icon.color=$COLOR label="zzz" label.color=0x66cdd6f4 label.drawing=yes
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
