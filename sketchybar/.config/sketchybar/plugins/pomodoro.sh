#!/usr/bin/env zsh

STATE_ROOT="${XDG_STATE_HOME:-$HOME/.local/state}"
STATE_DIR="$STATE_ROOT/sketchybar"
STATE_FILE="$STATE_DIR/pomodoro.state"
LOCK_FILE="$STATE_DIR/.pomodoro.lock"
SHLOCK=/usr/bin/shlock
LOCK_HELD=0
ACTIVE_TEMP_FILE=
STATE_PATH_INVALID=0
MAX_TIME=999999999999999999

WORK_DURATION=1500   # 25 min
BREAK_DURATION=300   # 5 min

source "$HOME/.config/sketchybar/colors.sh"

# Gruvbox Material colors
COLOR_WORK=$GREEN
COLOR_BREAK=$ORANGE
COLOR_IDLE=$BG_OVERLAY
COLOR_DONE=$RED

set_idle() {
    STATE="idle"
    MODE="work"
    DEADLINE=0
    REMAINING=0
}

is_nonnegative_integer() {
    case "$1" in
    ""|*[!0-9]*) return 1 ;;
    *) return 0 ;;
    esac
}

load_state() {
    local version_line state_line mode_line deadline_line remaining_line extra_line

    {
        IFS= read -r version_line &&
            IFS= read -r state_line &&
            IFS= read -r mode_line &&
            IFS= read -r deadline_line &&
            IFS= read -r remaining_line
        if IFS= read -r extra_line; then
            return 1
        fi
    } < "$STATE_FILE" || return 1

    [[ "$version_line" == "version=1" ]] || return 1
    [[ "$state_line" == state=* ]] || return 1
    [[ "$mode_line" == mode=* ]] || return 1
    [[ "$deadline_line" == deadline=* ]] || return 1
    [[ "$remaining_line" == remaining=* ]] || return 1

    STATE=${state_line#state=}
    MODE=${mode_line#mode=}
    DEADLINE=${deadline_line#deadline=}
    REMAINING=${remaining_line#remaining=}

    case "$STATE" in
    idle|running|paused) ;;
    *) return 1 ;;
    esac
    case "$MODE" in
    work|break) ;;
    *) return 1 ;;
    esac
    is_nonnegative_integer "$DEADLINE" || return 1
    is_nonnegative_integer "$REMAINING" || return 1
    [[ ${#DEADLINE} -le 18 && ${#REMAINING} -le 18 ]] || return 1

    case "$STATE" in
    idle)
        [[ "$MODE" == "work" && "$DEADLINE" == 0 && "$REMAINING" == 0 ]]
        ;;
    running)
        [[ "$DEADLINE" -gt 0 && "$REMAINING" == 0 ]]
        ;;
    paused)
        [[ "$DEADLINE" == 0 && "$REMAINING" -gt 0 ]]
        ;;
    esac
}

get_state() {
    set_idle
    STATE_PATH_INVALID=0
    ensure_state_dir || {
        STATE_PATH_INVALID=1
        return
    }
    [[ ! -L "$STATE_FILE" ]] || {
        STATE_PATH_INVALID=1
        return
    }
    [[ -e "$STATE_FILE" ]] || return
    [[ -f "$STATE_FILE" ]] || {
        STATE_PATH_INVALID=1
        return
    }

    chmod 600 "$STATE_FILE" 2>/dev/null || {
        STATE_PATH_INVALID=1
        return
    }
    [[ ! -L "$STATE_FILE" && -f "$STATE_FILE" ]] || {
        STATE_PATH_INVALID=1
        return
    }
    load_state || set_idle
}

ensure_state_dir() {
    umask 077

    if [[ -L "$STATE_DIR" || ( -e "$STATE_DIR" && ! -d "$STATE_DIR" ) ]]; then
        return 1
    fi

    if [[ ! -d "$STATE_DIR" ]]; then
        mkdir -p "$STATE_ROOT" || return 1
        if ! mkdir "$STATE_DIR" 2>/dev/null; then
            [[ ! -L "$STATE_DIR" && -d "$STATE_DIR" ]] || return 1
        fi
    fi

    [[ ! -L "$STATE_DIR" && -d "$STATE_DIR" ]] || return 1
    chmod 700 "$STATE_DIR" || return 1
    [[ ! -L "$STATE_DIR" && -d "$STATE_DIR" ]] || return 1
}

remove_regular_file() {
    local file_path=$1

    [[ ! -L "$file_path" && -f "$file_path" ]] || return 1
    rm -f "$file_path"
}

read_lock_owner() {
    local lock_owner extra_line

    [[ ! -L "$LOCK_FILE" && -f "$LOCK_FILE" ]] || return 1
    {
        IFS= read -r lock_owner || return 1
        if IFS= read -r extra_line; then
            return 1
        fi
    } < "$LOCK_FILE"
    [[ "$lock_owner" == "$$" ]] || return 1
}

release_lock() {
    [[ "$LOCK_HELD" == 1 ]] || return
    if read_lock_owner; then
        remove_regular_file "$LOCK_FILE"
    fi
    LOCK_HELD=0
}

acquire_lock() {
    [[ -x "$SHLOCK" ]] || return 1
    [[ ! -L "$LOCK_FILE" ]] || return 1
    [[ ! -e "$LOCK_FILE" || -f "$LOCK_FILE" ]] || return 1

    umask 077
    "$SHLOCK" -f "$LOCK_FILE" -p $$ || return 1
    LOCK_HELD=1
    [[ ! -L "$LOCK_FILE" && -f "$LOCK_FILE" ]] || return 1
    chmod 600 "$LOCK_FILE" || {
        release_lock
        return 1
    }
    read_lock_owner || {
        LOCK_HELD=0
        return 1
    }
}

state_file_is_safe_or_absent() {
    [[ ! -L "$STATE_FILE" ]] || return 1
    [[ ! -e "$STATE_FILE" || -f "$STATE_FILE" ]]
}

remove_temporary_file() {
    local temporary_file=$1

    case "$temporary_file" in
    "$STATE_DIR"/.pomodoro.state.*)
        [[ ! -L "$temporary_file" && -f "$temporary_file" ]] && rm -f "$temporary_file"
        ;;
    esac
}

cleanup_active_temp_file() {
    local temporary_file=$ACTIVE_TEMP_FILE

    ACTIVE_TEMP_FILE=
    [[ -n "$temporary_file" ]] || return
    remove_temporary_file "$temporary_file"
}

cleanup_runtime() {
    cleanup_active_temp_file
    release_lock
}

save_state() {
    local temporary_file

    ensure_state_dir || return 1
    state_file_is_safe_or_absent || return 1
    temporary_file=$(mktemp "$STATE_DIR/.pomodoro.state.XXXXXX") || return 1
    [[ ! -L "$temporary_file" && -f "$temporary_file" ]] || return 1
    ACTIVE_TEMP_FILE=$temporary_file
    chmod 600 "$temporary_file" || {
        cleanup_active_temp_file
        return 1
    }
    [[ ! -L "$temporary_file" && -f "$temporary_file" ]] || return 1

    if ! printf 'version=1\nstate=%s\nmode=%s\ndeadline=%s\nremaining=%s\n' \
        "$STATE" "$MODE" "$DEADLINE" "$REMAINING" > "$temporary_file"; then
        cleanup_active_temp_file
        return 1
    fi

    state_file_is_safe_or_absent || {
        cleanup_active_temp_file
        return 1
    }
    if ! mv -f "$temporary_file" "$STATE_FILE"; then
        cleanup_active_temp_file
        return 1
    fi
    ACTIVE_TEMP_FILE=
    [[ ! -L "$STATE_FILE" && -f "$STATE_FILE" ]]
}

read_now() {
    local current_time

    current_time=$(date +%s) || return 1
    is_nonnegative_integer "$current_time" || return 1
    [[ ${#current_time} -le 18 ]] || return 1
    NOW=$current_time
}

render_idle() {
    sketchybar --set $NAME icon=󰔟 label="off" background.color=$COLOR_IDLE icon.color=$FG
}

render_timer() {
    local display_seconds=$1
    local minutes seconds display

    minutes=$((display_seconds / 60))
    seconds=$((display_seconds % 60))
    display=$(printf "%02d:%02d" $minutes $seconds)

    if [[ "$MODE" == "work" ]]; then
        sketchybar --set $NAME icon=󰔟 label="$display" background.color=$COLOR_WORK icon.color=$BAR_COLOR
    else
        sketchybar --set $NAME icon=󰾩 label="$display" background.color=$COLOR_BREAK icon.color=$BAR_COLOR
    fi
}

transition_expired() {
    local current_time=$1

    if [[ "$MODE" == "work" ]]; then
        [[ "$current_time" -le $((MAX_TIME - BREAK_DURATION)) ]] || {
            render_idle
            return 1
        }
        MODE="break"
        STATE="running"
        DEADLINE=$((current_time + BREAK_DURATION))
        REMAINING=0
        if ! save_state; then
            return 1
        fi
        sketchybar --set $NAME icon=󰾩 label="break!" background.color=$COLOR_DONE icon.color=$BAR_COLOR
        release_lock
        osascript -e 'display notification "Time for a break!" with title "Pomodoro"'
        return
    fi

    set_idle
    if ! save_state; then
        return 1
    fi
    render_idle
    release_lock
    osascript -e 'display notification "Break over. Ready for another?" with title "Pomodoro"'
}

update_display() {
    local display_seconds

    get_state
    if [[ "$STATE_PATH_INVALID" == 1 ]]; then
        render_idle
        return
    fi

    if [[ "$STATE" == "idle" ]]; then
        render_idle
        return
    fi

    if [[ "$STATE" == "paused" ]]; then
        render_timer "$REMAINING"
        return
    fi

    read_now || {
        render_idle
        return
    }
    display_seconds=$((DEADLINE - NOW))
    if [[ $display_seconds -le 0 ]]; then
        transition_expired "$NOW"
        return
    fi
    render_timer "$display_seconds"
}

start_pause() {
    local display_seconds

    get_state
    if [[ "$STATE_PATH_INVALID" == 1 ]]; then
        render_idle
        return
    fi

    if [[ "$STATE" == "idle" ]]; then
        read_now || {
            render_idle
            return
        }
        [[ "$NOW" -le $((MAX_TIME - WORK_DURATION)) ]] || {
            render_idle
            return
        }
        STATE="running"
        MODE="work"
        DEADLINE=$((NOW + WORK_DURATION))
        REMAINING=0
        if save_state; then
            render_timer "$WORK_DURATION"
        fi
    elif [[ "$STATE" == "running" ]]; then
        read_now || {
            render_idle
            return
        }
        display_seconds=$((DEADLINE - NOW))
        if [[ $display_seconds -le 0 ]]; then
            transition_expired "$NOW"
            return
        fi
        REMAINING=$display_seconds
        STATE="paused"
        DEADLINE=0
        if save_state; then
            render_timer "$REMAINING"
        fi
    elif [[ "$STATE" == "paused" ]]; then
        read_now || {
            render_idle
            return
        }
        [[ "$NOW" -le $((MAX_TIME - REMAINING)) ]] || {
            render_idle
            return
        }
        STATE="running"
        DEADLINE=$((NOW + REMAINING))
        display_seconds=$REMAINING
        REMAINING=0
        if save_state; then
            render_timer "$display_seconds"
        fi
    fi
}

reset() {
    get_state
    if [[ "$STATE_PATH_INVALID" == 1 ]]; then
        render_idle
        return
    fi
    set_idle
    save_state && render_idle
}

if ! ensure_state_dir; then
    render_idle
    exit 0
fi

trap 'cleanup_runtime' EXIT
trap 'cleanup_runtime; exit 1' HUP INT TERM
acquire_lock || exit 0

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
