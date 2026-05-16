#!/usr/bin/env zsh

POMODORO_FILE="/tmp/sketchybar_pomodoro"

WORK_DURATION=1500   # 25 min
BREAK_DURATION=300   # 5 min

source "$HOME/.config/sketchybar/colors.sh"

# Gruvbox Material colors
COLOR_WORK=$GREEN
COLOR_BREAK=$ORANGE
COLOR_IDLE=$BG_OVERLAY
COLOR_DONE=$RED

get_state() {
    if [[ -f "$POMODORO_FILE" ]]; then
        source "$POMODORO_FILE"
    else
        STATE="idle"
        END_TIME=0
        MODE="work"
    fi
}

save_state() {
    echo "STATE=\"$STATE\"\nEND_TIME=$END_TIME\nMODE=\"$MODE\"" > "$POMODORO_FILE"
}

update_display() {
    get_state

    if [[ "$STATE" == "idle" ]]; then
        sketchybar --set $NAME icon=󰔟 label="off" background.color=$COLOR_IDLE icon.color=$FG
        return
    fi

    NOW=$(date +%s)
    REMAINING=$((END_TIME - NOW))

    if [[ $REMAINING -le 0 ]]; then
        if [[ "$MODE" == "work" ]]; then
            # Work done, start break
            MODE="break"
            STATE="running"
            END_TIME=$((NOW + BREAK_DURATION))
            save_state
            sketchybar --set $NAME icon=󰾩 label="break!" background.color=$COLOR_DONE icon.color=$BAR_COLOR
            osascript -e 'display notification "Time for a break!" with title "Pomodoro"' &
        else
            # Break done
            STATE="idle"
            MODE="work"
            save_state
            sketchybar --set $NAME icon=󰔟 label="off" background.color=$COLOR_IDLE icon.color=$FG
            osascript -e 'display notification "Break over. Ready for another?" with title "Pomodoro"' &
        fi
        return
    fi

    MINS=$((REMAINING / 60))
    SECS=$((REMAINING % 60))
    DISPLAY=$(printf "%02d:%02d" $MINS $SECS)

    if [[ "$MODE" == "work" ]]; then
        sketchybar --set $NAME icon=󰔟 label="$DISPLAY" background.color=$COLOR_WORK icon.color=$BAR_COLOR
    else
        sketchybar --set $NAME icon=󰾩 label="$DISPLAY" background.color=$COLOR_BREAK icon.color=$BAR_COLOR
    fi
}

start_pause() {
    get_state

    if [[ "$STATE" == "idle" ]]; then
        STATE="running"
        MODE="work"
        END_TIME=$(( $(date +%s) + WORK_DURATION ))
        save_state
    elif [[ "$STATE" == "running" ]]; then
        REMAINING=$((END_TIME - $(date +%s)))
        STATE="paused"
        END_TIME=$REMAINING  # store remaining as temp
        save_state
    elif [[ "$STATE" == "paused" ]]; then
        STATE="running"
        END_TIME=$(( $(date +%s) + END_TIME ))  # restore from remaining
        save_state
    fi

    update_display
}

reset() {
    STATE="idle"
    MODE="work"
    END_TIME=0
    save_state
    update_display
}

case "$SENDER" in
"mouse.clicked")
    if [[ "$BUTTON" == "right" ]]; then
        reset
    else
        start_pause
    fi
    ;;
*)
    update_display
    ;;
esac
