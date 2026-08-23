#!/usr/bin/env bash

set -u

TEST_DIR=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)
PLUGIN="$TEST_DIR/../.config/sketchybar/plugins/pomodoro.sh"
TEST_ROOT=$(mktemp -d "${TMPDIR:-/tmp}/pomodoro-test.XXXXXX") || exit 1
PASS_COUNT=0
FAIL_COUNT=0

cleanup() {
    rm -rf "$TEST_ROOT"
}
trap cleanup EXIT HUP INT TERM

pass() {
    PASS_COUNT=$((PASS_COUNT + 1))
    printf 'ok - %s\n' "$1"
}

fail() {
    FAIL_COUNT=$((FAIL_COUNT + 1))
    printf 'not ok - %s\n' "$1"
}

assert_eq() {
    expected=$1
    actual=$2
    message=$3
    if [ "$actual" = "$expected" ]; then
        return 0
    fi
    printf '  expected: %s\n  actual:   %s\n' "$expected" "$actual"
    fail "$message"
    return 1
}

assert_file_contains() {
    file=$1
    expected=$2
    message=$3
    if grep -F -- "$expected" "$file" >/dev/null 2>&1; then
        return 0
    fi
    printf '  missing from %s: %s\n' "$file" "$expected"
    fail "$message"
    return 1
}

assert_file_not_contains() {
    file=$1
    unexpected=$2
    message=$3
    if grep -F -- "$unexpected" "$file" >/dev/null 2>&1; then
        printf '  unexpected in %s: %s\n' "$file" "$unexpected"
        fail "$message"
        return 1
    fi
    return 0
}

assert_file_not_matches() {
    file=$1
    unexpected=$2
    message=$3
    if grep -E -- "$unexpected" "$file" >/dev/null 2>&1; then
        printf '  unexpected pattern in %s: %s\n' "$file" "$unexpected"
        fail "$message"
        return 1
    fi
    return 0
}

new_case() {
    case_name=$1
    CASE_ROOT="$TEST_ROOT/$case_name"
    TEST_HOME="$CASE_ROOT/home"
    XDG_STATE_HOME="$CASE_ROOT/state"
    FAKE_BIN="$CASE_ROOT/bin"
    SKETCHYBAR_LOG="$CASE_ROOT/sketchybar.log"
    MV_LOG="$CASE_ROOT/mv.log"
    OSASCRIPT_LOG="$CASE_ROOT/osascript.log"
    STATE_DIR="$XDG_STATE_HOME/sketchybar"
    STATE_FILE="$STATE_DIR/pomodoro.state"
    LOCK_FILE="$STATE_DIR/.pomodoro.lock"

    mkdir -p "$TEST_HOME/.config/sketchybar" "$XDG_STATE_HOME" "$FAKE_BIN"
    : > "$SKETCHYBAR_LOG"
    : > "$MV_LOG"
    : > "$OSASCRIPT_LOG"

    cat > "$TEST_HOME/.config/sketchybar/colors.sh" <<'EOF'
GREEN=green
ORANGE=orange
BG_OVERLAY=idle
RED=red
FG=foreground
BAR_COLOR=bar
EOF

    cat > "$FAKE_BIN/date" <<'EOF'
#!/usr/bin/env bash
if [ "${1:-}" = "+%s" ]; then
    [ "${FAKE_DATE_FAIL:-}" != 1 ] || exit 1
    if [ "${FAKE_DATE_BLOCK:-}" = 1 ]; then
        : > "$DATE_READY"
        wait_count=0
        while [ ! -e "$DATE_RELEASE" ] && [ "$wait_count" -lt 1000 ]; do
            sleep 0.02
            wait_count=$((wait_count + 1))
        done
        [ -e "$DATE_RELEASE" ] || exit 1
    fi
    printf '%s\n' "$FAKE_NOW"
else
    /bin/date "$@"
fi
EOF
    cat > "$FAKE_BIN/sketchybar" <<'EOF'
#!/usr/bin/env bash
printf '%s\n' "$*" >> "$SKETCHYBAR_LOG"
EOF
    cat > "$FAKE_BIN/osascript" <<'EOF'
#!/usr/bin/env bash
printf '%s\n' "$*" >> "$OSASCRIPT_LOG"
if [ "${FAKE_OSASCRIPT_BLOCK:-}" = 1 ]; then
    : > "$OSASCRIPT_READY"
    wait_count=0
    while [ ! -e "$OSASCRIPT_RELEASE" ] && [ "$wait_count" -lt 1000 ]; do
        sleep 0.02
        wait_count=$((wait_count + 1))
    done
    [ -e "$OSASCRIPT_RELEASE" ] || exit 1
fi
EOF
    cat > "$FAKE_BIN/mv" <<'EOF'
#!/usr/bin/env bash
if [ "${1:-}" = "-f" ]; then
    source_path=$2
    destination_path=$3
else
    source_path=$1
    destination_path=$2
fi
source_mode=$(/usr/bin/stat -f '%Lp' "$source_path")
printf '%s|%s|%s\n' "$source_path" "$destination_path" "$source_mode" >> "$MV_LOG"
[ "${FAKE_MV_SIGNAL_PARENT:-}" != 1 ] || {
    kill -TERM "$PPID"
    sleep 0.05
    exit 1
}
[ "${FAKE_MV_DELAY:-0}" = 0 ] || sleep "$FAKE_MV_DELAY"
[ "${FAIL_SAVE_STAGE:-}" != mv ] || exit 1
/bin/mv "$@"
EOF
    cat > "$FAKE_BIN/mktemp" <<'EOF'
#!/usr/bin/env bash
[ "${FAIL_SAVE_STAGE:-}" != mktemp ] || exit 1
/usr/bin/mktemp "$@"
EOF
    cat > "$FAKE_BIN/chmod" <<'EOF'
#!/usr/bin/env bash
last_argument=
for argument in "$@"; do
    last_argument=$argument
done
case "$last_argument" in
*/.pomodoro.state.*)
    [ "${FAIL_SAVE_STAGE:-}" != chmod ] || exit 1
    ;;
esac
/bin/chmod "$@"
EOF
    cat > "$FAKE_BIN/printf" <<'EOF'
#!/usr/bin/env bash
case "${1:-}" in
version=1*)
    [ "${FAIL_SAVE_STAGE:-}" != state_printf ] || exit 1
    ;;
esac
/usr/bin/printf "$@"
EOF
    chmod +x "$FAKE_BIN/date" "$FAKE_BIN/sketchybar" "$FAKE_BIN/osascript" \
        "$FAKE_BIN/mv" "$FAKE_BIN/mktemp" "$FAKE_BIN/chmod" "$FAKE_BIN/printf"
}

run_plugin() {
    sender=$1
    button=$2
    now=$3
    command_path=/bin/zsh
    command_option=
    command_argument=$PLUGIN
    if [ "${FAIL_SAVE_STAGE:-}" = state_printf ]; then
        command_option=-c
        command_argument='disable printf; source "$PLUGIN"'
    fi

    env \
        HOME="$TEST_HOME" \
        XDG_STATE_HOME="$XDG_STATE_HOME" \
        PATH="$FAKE_BIN:/usr/bin:/bin" \
        NAME=pomodoro \
        SENDER="$sender" \
        BUTTON="$button" \
        FAKE_NOW="$now" \
        SKETCHYBAR_LOG="$SKETCHYBAR_LOG" \
        MV_LOG="$MV_LOG" \
        OSASCRIPT_LOG="$OSASCRIPT_LOG" \
        OSASCRIPT_READY="$CASE_ROOT/osascript.ready" \
        OSASCRIPT_RELEASE="$CASE_ROOT/osascript.release" \
        DATE_READY="$CASE_ROOT/date.ready" \
        DATE_RELEASE="$CASE_ROOT/date.release" \
        FAIL_SAVE_STAGE="${FAIL_SAVE_STAGE:-}" \
        FAKE_DATE_FAIL="${FAKE_DATE_FAIL:-}" \
        FAKE_DATE_BLOCK="${FAKE_DATE_BLOCK:-}" \
        FAKE_MV_DELAY="${FAKE_MV_DELAY:-0}" \
        FAKE_MV_SIGNAL_PARENT="${FAKE_MV_SIGNAL_PARENT:-}" \
        FAKE_OSASCRIPT_BLOCK="${FAKE_OSASCRIPT_BLOCK:-}" \
        PLUGIN="$PLUGIN" \
        "$command_path" ${command_option:+"$command_option"} "$command_argument"
}

write_state() {
    state=$1
    mode=$2
    deadline=$3
    remaining=$4
    mkdir -p "$STATE_DIR"
    printf 'version=1\nstate=%s\nmode=%s\ndeadline=%s\nremaining=%s\n' \
        "$state" "$mode" "$deadline" "$remaining" > "$STATE_FILE"
    chmod 600 "$STATE_FILE"
}

test_static_state_safety() {
    failed=0
    assert_file_not_contains "$PLUGIN" '/tmp/sketchybar_pomodoro' \
        'plugin does not reference the legacy state file' || failed=1
    assert_file_not_matches "$PLUGIN" 'source.*(POMODORO|STATE).*FILE' \
        'plugin never sources persisted state' || failed=1
    assert_file_not_contains "$PLUGIN" 'rm -rf' \
        'plugin never recursively removes lock or state paths' || failed=1
    assert_file_contains "$PLUGIN" 'SHLOCK=/usr/bin/shlock' \
        'plugin uses the native macOS shlock path' || failed=1
    assert_file_contains "$PLUGIN" '[[ -x "$SHLOCK" ]] || return 1' \
        'plugin fails closed when native shlock is unavailable' || failed=1
    assert_file_contains "$PLUGIN" '"$SHLOCK" -f "$LOCK_FILE" -p $$' \
        'plugin delegates atomic PID locking and stale recovery to shlock' || failed=1
    [ "$failed" -eq 0 ] && pass 'state storage has no source or legacy /tmp use'
}

test_valid_states() {
    failed=0

    new_case valid_idle
    write_state idle work 0 0
    run_plugin routine '' 1000 || failed=1
    assert_file_contains "$SKETCHYBAR_LOG" 'label=off' 'idle state renders off' || failed=1
    assert_eq 700 "$(/usr/bin/stat -f '%Lp' "$STATE_DIR")" 'existing state directory is corrected to mode 0700' || failed=1

    new_case valid_running_work
    write_state running work 1120 0
    run_plugin routine '' 1000 || failed=1
    assert_file_contains "$SKETCHYBAR_LOG" 'label=02:00' 'running work state renders its deadline' || failed=1
    assert_file_contains "$SKETCHYBAR_LOG" 'background.color=green' 'running work state uses work color' || failed=1

    new_case valid_running_break
    write_state running break 1090 0
    run_plugin routine '' 1000 || failed=1
    assert_file_contains "$SKETCHYBAR_LOG" 'label=01:30' 'running break state renders its deadline' || failed=1
    assert_file_contains "$SKETCHYBAR_LOG" 'background.color=orange' 'running break state uses break color' || failed=1

    new_case valid_paused
    write_state paused work 0 75
    run_plugin routine '' 1000 || failed=1
    assert_file_contains "$SKETCHYBAR_LOG" 'label=01:15' 'paused state renders stored remaining time' || failed=1

    [ "$failed" -eq 0 ] && pass 'all valid persisted states render safely'
}

test_default_state_home() {
    new_case default_state_home
    fallback_file="$TEST_HOME/.local/state/sketchybar/pomodoro.state"

    if ! env -u XDG_STATE_HOME \
        HOME="$TEST_HOME" \
        PATH="$FAKE_BIN:/usr/bin:/bin" \
        NAME=pomodoro \
        SENDER=mouse.clicked \
        BUTTON=left \
        FAKE_NOW=1000 \
        SKETCHYBAR_LOG="$SKETCHYBAR_LOG" \
        MV_LOG="$MV_LOG" \
        OSASCRIPT_LOG="$OSASCRIPT_LOG" \
        /bin/zsh "$PLUGIN"; then
        fail 'default state home supports starting a session'
        return
    fi

    if [ -f "$fallback_file" ]; then
        pass 'state defaults to HOME/.local/state when XDG_STATE_HOME is unset'
    else
        fail 'state defaults to HOME/.local/state when XDG_STATE_HOME is unset'
    fi
}

test_permissions_and_atomic_write() {
    new_case permissions
    mkdir -p "$STATE_DIR"
    chmod 755 "$STATE_DIR"

    if ! run_plugin mouse.clicked left 1000; then
        fail 'starting a session writes state successfully'
        return
    fi

    failed=0
    assert_eq 700 "$(/usr/bin/stat -f '%Lp' "$STATE_DIR")" 'state directory has mode 0700' || failed=1
    assert_eq 600 "$(/usr/bin/stat -f '%Lp' "$STATE_FILE")" 'state file has mode 0600' || failed=1
    assert_file_contains "$MV_LOG" "$STATE_DIR/.pomodoro.state." 'atomic write uses a temporary file in the state directory' || failed=1
    assert_file_contains "$MV_LOG" "|$STATE_FILE|600" 'atomic write renames a mode 0600 temporary file over state' || failed=1
    [ "$failed" -eq 0 ] && pass 'state writes are private and atomically renamed'
}

test_rejects_unsafe_state_paths() {
    failed=0

    new_case symlink_state_dir
    external_dir="$CASE_ROOT/external"
    mkdir -p "$external_dir"
    chmod 755 "$external_dir"
    printf 'external bytes\n' > "$external_dir/sentinel"
    external_checksum=$(/usr/bin/cksum < "$external_dir/sentinel")
    ln -s "$external_dir" "$STATE_DIR"
    run_plugin routine '' 1000 || failed=1
    assert_eq 755 "$(/usr/bin/stat -f '%Lp' "$external_dir")" 'state directory symlink target mode is unchanged' || failed=1
    assert_eq "$external_checksum" "$(/usr/bin/cksum < "$external_dir/sentinel")" 'state directory symlink target bytes are unchanged' || failed=1
    assert_file_contains "$SKETCHYBAR_LOG" 'label=off' 'unsafe state directory renders safe idle UI' || failed=1

    new_case non_directory_state_dir
    printf 'not a directory\n' > "$STATE_DIR"
    chmod 644 "$STATE_DIR"
    state_dir_checksum=$(/usr/bin/cksum < "$STATE_DIR")
    run_plugin routine '' 1000 || failed=1
    assert_eq 644 "$(/usr/bin/stat -f '%Lp' "$STATE_DIR")" 'non-directory state path mode is unchanged' || failed=1
    assert_eq "$state_dir_checksum" "$(/usr/bin/cksum < "$STATE_DIR")" 'non-directory state path bytes are unchanged' || failed=1
    assert_file_contains "$SKETCHYBAR_LOG" 'label=off' 'non-directory state path renders safe idle UI' || failed=1

    new_case symlink_state_file
    mkdir -p "$STATE_DIR"
    chmod 700 "$STATE_DIR"
    external_file="$CASE_ROOT/external.state"
    printf 'external state bytes\n' > "$external_file"
    chmod 644 "$external_file"
    external_checksum=$(/usr/bin/cksum < "$external_file")
    ln -s "$external_file" "$STATE_FILE"
    run_plugin mouse.clicked middle 1000 || failed=1
    assert_eq 644 "$(/usr/bin/stat -f '%Lp' "$external_file")" 'state file symlink target mode is unchanged' || failed=1
    assert_eq "$external_checksum" "$(/usr/bin/cksum < "$external_file")" 'state file symlink target bytes are unchanged' || failed=1
    assert_file_contains "$SKETCHYBAR_LOG" 'label=off' 'unsafe state file renders safe idle UI' || failed=1

    new_case non_regular_state_file
    mkdir -p "$STATE_FILE"
    chmod 755 "$STATE_FILE"
    run_plugin routine '' 1000 || failed=1
    assert_eq 755 "$(/usr/bin/stat -f '%Lp' "$STATE_FILE")" 'non-regular state file mode is unchanged' || failed=1
    assert_file_contains "$SKETCHYBAR_LOG" 'label=off' 'non-regular state file renders safe idle UI' || failed=1

    [ "$failed" -eq 0 ] && pass 'unsafe state paths are rejected without following targets'
}

test_failed_saves_never_publish_transitions() {
    failed=0
    for stage in mktemp chmod state_printf mv; do
        new_case "save_failure_$stage"
        write_state running work 900 0
        original_checksum=$(/usr/bin/cksum < "$STATE_FILE")
        FAIL_SAVE_STAGE=$stage run_plugin routine '' 1000 || true

        assert_eq "$original_checksum" "$(/usr/bin/cksum < "$STATE_FILE")" "$stage failure preserves persisted state" || failed=1
        assert_eq 0 "$(wc -l < "$SKETCHYBAR_LOG" | tr -d ' ')" "$stage failure does not publish unpersisted UI" || failed=1
        assert_eq 0 "$(wc -l < "$OSASCRIPT_LOG" | tr -d ' ')" "$stage failure does not notify" || failed=1
    done

    [ "$failed" -eq 0 ] && pass 'failed saves never publish or notify transitions'
}

test_signal_cleans_active_tempfile_before_locks() {
    new_case signal_cleanup
    write_state running work 900 0
    original_checksum=$(/usr/bin/cksum < "$STATE_FILE")

    FAKE_MV_SIGNAL_PARENT=1 run_plugin routine '' 1000 || true

    failed=0
    assert_eq "$original_checksum" "$(/usr/bin/cksum < "$STATE_FILE")" 'signal before rename preserves persisted state' || failed=1
    temporary_found=0
    for temporary_path in "$STATE_DIR"/.pomodoro.state.*; do
        [ ! -e "$temporary_path" ] || temporary_found=1
    done
    assert_eq 0 "$temporary_found" 'signal trap removes the exact active temporary file' || failed=1
    [ ! -e "$LOCK_FILE" ] || { fail 'signal trap releases the lock file'; failed=1; }
    assert_eq 0 "$(wc -l < "$SKETCHYBAR_LOG" | tr -d ' ')" 'signal does not publish UI' || failed=1
    assert_eq 0 "$(wc -l < "$OSASCRIPT_LOG" | tr -d ' ')" 'signal does not notify' || failed=1

    [ "$failed" -eq 0 ] && pass 'signal cleanup removes the active tempfile before locks'
}

test_lock_file_safety_and_shlock_requirement() {
    failed=0

    new_case symlink_lock_file
    mkdir -p "$STATE_DIR"
    external_lock="$CASE_ROOT/external.lock"
    printf '%s\n' "$$" > "$external_lock"
    chmod 644 "$external_lock"
    external_checksum=$(/usr/bin/cksum < "$external_lock")
    ln -s "$external_lock" "$LOCK_FILE"
    run_plugin mouse.clicked middle 1000 || failed=1
    assert_eq 644 "$(/usr/bin/stat -f '%Lp' "$external_lock")" 'lock symlink target mode is unchanged' || failed=1
    assert_eq "$external_checksum" "$(/usr/bin/cksum < "$external_lock")" 'lock symlink target bytes are unchanged' || failed=1
    [ ! -e "$STATE_FILE" ] || { fail 'lock symlink blocks state mutation'; failed=1; }
    assert_eq 0 "$(wc -l < "$SKETCHYBAR_LOG" | tr -d ' ')" 'lock symlink blocks UI mutation' || failed=1

    new_case non_regular_lock_file
    mkdir -p "$STATE_DIR"
    mkdir "$LOCK_FILE"
    chmod 755 "$LOCK_FILE"
    run_plugin mouse.clicked middle 1000 || failed=1
    assert_eq 755 "$(/usr/bin/stat -f '%Lp' "$LOCK_FILE")" 'non-regular lock mode is unchanged' || failed=1
    [ ! -e "$STATE_FILE" ] || { fail 'non-regular lock blocks state mutation'; failed=1; }
    assert_eq 0 "$(wc -l < "$SKETCHYBAR_LOG" | tr -d ' ')" 'non-regular lock blocks UI mutation' || failed=1

    new_case unavailable_shlock
    unavailable_plugin="$CASE_ROOT/pomodoro-no-shlock.sh"
    /usr/bin/sed 's|^SHLOCK=/usr/bin/shlock$|SHLOCK=/nonexistent/shlock|' "$PLUGIN" > "$unavailable_plugin"
    chmod +x "$unavailable_plugin"
    original_plugin=$PLUGIN
    PLUGIN=$unavailable_plugin
    run_plugin mouse.clicked middle 1000 || true
    PLUGIN=$original_plugin
    [ ! -e "$STATE_FILE" ] || { fail 'unavailable shlock blocks state mutation'; failed=1; }
    assert_eq 0 "$(wc -l < "$SKETCHYBAR_LOG" | tr -d ' ')" 'unavailable shlock blocks UI mutation' || failed=1
    assert_eq 0 "$(wc -l < "$OSASCRIPT_LOG" | tr -d ' ')" 'unavailable shlock blocks notification' || failed=1

    [ "$failed" -eq 0 ] && pass 'unsafe lock files and unavailable shlock fail closed'
}

test_notification_does_not_hold_locks() {
    new_case notification_lock_release
    write_state running work 900 0
    failed=0

    FAKE_OSASCRIPT_BLOCK=1 run_plugin routine '' 1000 &
    notification_pid=$!
    notification_wait_count=0
    while [ ! -e "$CASE_ROOT/osascript.ready" ] && [ "$notification_wait_count" -lt 500 ]; do
        sleep 0.02
        notification_wait_count=$((notification_wait_count + 1))
    done
    [ -e "$CASE_ROOT/osascript.ready" ] || { fail 'notification fake reaches its blocking point'; failed=1; }
    [ ! -e "$LOCK_FILE" ] || { fail 'lock file is released before notification'; failed=1; }

    run_plugin routine '' 1000 || failed=1
    assert_file_contains "$SKETCHYBAR_LOG" 'label=05:00' 'another update runs while notification is blocked' || failed=1
    : > "$CASE_ROOT/osascript.release"
    wait "$notification_pid" || failed=1
    assert_eq 1 "$(wc -l < "$OSASCRIPT_LOG" | tr -d ' ')" 'blocked notification is emitted once' || failed=1

    [ "$failed" -eq 0 ] && pass 'notification runs after explicit lock release'
}

test_concurrent_expiry_stress() {
    new_case concurrent_expiry_stress
    write_state running work 900 0
    failed=0
    stress_pids=
    stress_count=0

    while [ "$stress_count" -lt 60 ]; do
        run_plugin routine '' 1000 &
        stress_pids="$stress_pids $!"
        stress_count=$((stress_count + 1))
    done
    for stress_pid in $stress_pids; do
        wait "$stress_pid" || failed=1
    done

    assert_eq 1 "$(wc -l < "$OSASCRIPT_LOG" | tr -d ' ')" 'stress expiry emits one notification' || failed=1
    assert_eq 1 "$(wc -l < "$MV_LOG" | tr -d ' ')" 'stress expiry persists one transition' || failed=1
    assert_file_contains "$STATE_FILE" 'mode=break' 'stress expiry leaves the committed break state' || failed=1
    [ ! -e "$LOCK_FILE" ] || { fail 'stress expiry releases the lock file'; failed=1; }

    [ "$failed" -eq 0 ] && pass 'sixty concurrent expirations serialize to one transition'
}

test_invalid_date_is_safe() {
    failed=0

    new_case date_command_failure
    FAKE_DATE_FAIL=1 run_plugin mouse.clicked middle 1000 || true
    [ ! -e "$STATE_FILE" ] || { fail 'date command failure does not persist state'; failed=1; }
    assert_file_contains "$SKETCHYBAR_LOG" 'label=off' 'date command failure renders safe idle UI' || failed=1
    assert_eq 0 "$(wc -l < "$OSASCRIPT_LOG" | tr -d ' ')" 'date command failure does not notify' || failed=1

    new_case date_invalid_output
    run_plugin mouse.clicked middle not-a-number || true
    [ ! -e "$STATE_FILE" ] || { fail 'invalid date output does not persist state'; failed=1; }
    assert_file_contains "$SKETCHYBAR_LOG" 'label=off' 'invalid date output renders safe idle UI' || failed=1

    new_case date_failure_running
    write_state running work 1120 0
    original_checksum=$(/usr/bin/cksum < "$STATE_FILE")
    FAKE_DATE_FAIL=1 run_plugin routine '' 1000 || true
    assert_eq "$original_checksum" "$(/usr/bin/cksum < "$STATE_FILE")" 'date failure preserves an active state' || failed=1
    assert_file_not_matches "$SKETCHYBAR_LOG" 'label=-?[0-9]+:' 'date failure does not display an invented time' || failed=1

    [ "$failed" -eq 0 ] && pass 'date failures cannot create deadlines or absurd displays'
}

test_shlock_serializes_and_recovers_sigkill_holder() {
    failed=0

    new_case concurrent_expiry
    write_state running work 900 0
    FAKE_MV_DELAY=1 run_plugin routine '' 1000 &
    first_pid=$!
    lock_wait_count=0
    while [ ! -f "$LOCK_FILE" ] && [ "$lock_wait_count" -lt 100 ]; do
        sleep 0.02
        lock_wait_count=$((lock_wait_count + 1))
    done
    if [ -f "$LOCK_FILE" ]; then
        assert_eq 600 "$(/usr/bin/stat -f '%Lp' "$LOCK_FILE")" 'active shlock file has mode 0600' || failed=1
    else
        fail 'active shlock file becomes observable during the serialized write'
        failed=1
    fi
    run_plugin routine '' 1000 &
    second_pid=$!
    wait "$first_pid" || failed=1
    wait "$second_pid" || failed=1
    sleep 0.1
    assert_eq 1 "$(wc -l < "$OSASCRIPT_LOG" | tr -d ' ')" 'concurrent expiry emits one notification' || failed=1
    assert_eq 1 "$(wc -l < "$MV_LOG" | tr -d ' ')" 'concurrent expiry persists one transition' || failed=1
    assert_file_contains "$STATE_FILE" 'mode=break' 'concurrent expiry commits one break transition' || failed=1
    [ ! -e "$LOCK_FILE" ] || { fail 'normal concurrency releases the lock file'; failed=1; }

    new_case live_lock
    mkdir -p "$STATE_DIR"
    umask 077
    /usr/bin/shlock -f "$LOCK_FILE" -p $$ || failed=1
    live_lock_checksum=$(/usr/bin/cksum < "$LOCK_FILE")
    run_plugin mouse.clicked middle 1000 || failed=1
    [ ! -e "$STATE_FILE" ] || { fail 'live lock prevents state mutation'; failed=1; }
    assert_eq "$live_lock_checksum" "$(/usr/bin/cksum < "$LOCK_FILE")" 'live lock remains owned by its holder' || failed=1
    assert_eq 0 "$(wc -l < "$SKETCHYBAR_LOG" | tr -d ' ')" 'live lock prevents UI mutation' || failed=1
    assert_eq 0 "$(wc -l < "$OSASCRIPT_LOG" | tr -d ' ')" 'live lock prevents notification' || failed=1
    rm -f "$LOCK_FILE"

    new_case sigkill_stale_lock
    write_state running work 900 0
    FAKE_DATE_BLOCK=1 run_plugin routine '' 1000 2>/dev/null &
    holder_wrapper_pid=$!
    holder_wait_count=0
    while [ ! -e "$CASE_ROOT/date.ready" ] && [ "$holder_wait_count" -lt 500 ]; do
        sleep 0.02
        holder_wait_count=$((holder_wait_count + 1))
    done
    [ -e "$CASE_ROOT/date.ready" ] || { fail 'SIGKILL holder reaches its blocking point'; failed=1; }
    if [ -f "$LOCK_FILE" ]; then
        IFS= read -r killed_holder_pid < "$LOCK_FILE"
        kill -KILL "$killed_holder_pid" 2>/dev/null || failed=1
    else
        fail 'SIGKILL holder owns a regular lock file'
        if [ -f "$LOCK_FILE/pid" ]; then
            IFS= read -r killed_holder_pid < "$LOCK_FILE/pid"
            kill -KILL "$killed_holder_pid" 2>/dev/null || true
        fi
        failed=1
    fi
    : > "$CASE_ROOT/date.release"
    wait "$holder_wrapper_pid" 2>/dev/null || true
    dead_wait_count=0
    while kill -0 "$killed_holder_pid" 2>/dev/null && [ "$dead_wait_count" -lt 500 ]; do
        sleep 0.02
        dead_wait_count=$((dead_wait_count + 1))
    done
    if kill -0 "$killed_holder_pid" 2>/dev/null; then
        fail 'SIGKILL holder PID is no longer live before stale recovery'
        failed=1
    fi
    [ -f "$LOCK_FILE" ] || { fail 'SIGKILL leaves an orphan lock file for shlock recovery'; failed=1; }
    sleep 1.1

    FAKE_MV_DELAY=1 run_plugin routine '' 1000 &
    stale_first_pid=$!
    recovered_wait_count=0
    recovered_owner=$killed_holder_pid
    while [ "$recovered_owner" = "$killed_holder_pid" ] && [ "$recovered_wait_count" -lt 500 ]; do
        if [ -f "$LOCK_FILE" ]; then
            IFS= read -r recovered_owner < "$LOCK_FILE"
        fi
        [ "$recovered_owner" != "$killed_holder_pid" ] || sleep 0.02
        recovered_wait_count=$((recovered_wait_count + 1))
    done
    [ "$recovered_owner" != "$killed_holder_pid" ] || { fail 'shlock atomically replaces the SIGKILL orphan'; failed=1; }
    run_plugin routine '' 1000 &
    stale_second_pid=$!
    wait "$stale_first_pid" || failed=1
    wait "$stale_second_pid" || failed=1
    assert_eq 1 "$(wc -l < "$OSASCRIPT_LOG" | tr -d ' ')" 'SIGKILL stale recovery emits one notification' || failed=1
    assert_eq 1 "$(wc -l < "$MV_LOG" | tr -d ' ')" 'SIGKILL stale recovery persists one transition' || failed=1
    assert_file_contains "$STATE_FILE" 'mode=break' 'SIGKILL stale recovery commits break state' || failed=1
    [ ! -e "$LOCK_FILE" ] || { fail 'SIGKILL stale recovery releases the lock file'; failed=1; }

    [ "$failed" -eq 0 ] && pass 'shlock serializes concurrency and recovers a SIGKILL orphan'
}

test_corrupt_state_is_inert_and_idle() {
    new_case corrupt
    mkdir -p "$STATE_DIR"
    marker="$CASE_ROOT/executed"
    cat > "$STATE_FILE" <<EOF
version=1
state=\$(touch "$marker")
mode=work
deadline=not-a-number
remaining=0
EOF

    if ! run_plugin routine '' 1000; then
        fail 'corrupt state does not break the plugin'
        return
    fi

    failed=0
    [ ! -e "$marker" ] || { fail 'corrupt state is parsed without execution'; failed=1; }
    assert_file_contains "$SKETCHYBAR_LOG" 'label=off' 'corrupt state falls back to idle' || failed=1
    [ "$failed" -eq 0 ] && pass 'corrupt state is inert and falls back to idle'
}

test_restart_and_expiry() {
    new_case restart
    failed=0

    run_plugin mouse.clicked left 1000 || failed=1
    assert_file_contains "$STATE_FILE" 'state=running' 'left click starts a running session' || failed=1
    assert_file_contains "$STATE_FILE" 'deadline=2500' 'running session stores an epoch deadline' || failed=1

    : > "$SKETCHYBAR_LOG"
    run_plugin routine '' 1060 || failed=1
    assert_file_contains "$SKETCHYBAR_LOG" 'label=24:00' 'active session continues after process restart' || failed=1

    write_state running work 900 0
    : > "$SKETCHYBAR_LOG"
    run_plugin routine '' 1000 || failed=1
    assert_file_contains "$STATE_FILE" 'mode=break' 'expired work transitions to break' || failed=1
    assert_file_contains "$STATE_FILE" 'deadline=1300' 'new break stores an epoch deadline' || failed=1

    write_state running break 900 0
    : > "$SKETCHYBAR_LOG"
    run_plugin routine '' 1000 || failed=1
    assert_file_contains "$STATE_FILE" 'state=idle' 'expired break returns to idle' || failed=1
    assert_file_contains "$SKETCHYBAR_LOG" 'label=off' 'expired break renders idle' || failed=1

    [ "$failed" -eq 0 ] && pass 'restart preserves active deadlines and expiry reaches the correct state'
}

test_pause_resume_uses_explicit_remaining_time() {
    new_case pause_resume
    failed=0

    write_state running work 1120 0
    run_plugin mouse.clicked left 1000 || failed=1
    assert_file_contains "$STATE_FILE" 'state=paused' 'click pauses a running session' || failed=1
    assert_file_contains "$STATE_FILE" 'deadline=0' 'paused state clears its deadline' || failed=1
    assert_file_contains "$STATE_FILE" 'remaining=120' 'paused state stores remaining seconds' || failed=1

    run_plugin mouse.clicked left 1060 || failed=1
    assert_file_contains "$STATE_FILE" 'state=running' 'click resumes a paused session' || failed=1
    assert_file_contains "$STATE_FILE" 'deadline=1180' 'resumed state creates a new epoch deadline' || failed=1
    assert_file_contains "$STATE_FILE" 'remaining=0' 'resumed state clears remaining seconds' || failed=1

    [ "$failed" -eq 0 ] && pass 'pause and resume preserve explicit remaining time'
}

test_invalid_inputs_and_click_semantics() {
    new_case invalid
    failed=0

    run_plugin mouse.clicked middle 1000 || failed=1
    assert_file_contains "$STATE_FILE" 'state=running' 'middle click starts a session like any non-right click' || failed=1

    run_plugin mouse.clicked right 1001 || failed=1
    assert_file_contains "$STATE_FILE" 'state=idle' 'right click resets the session' || failed=1

    write_state running work -1 0
    : > "$SKETCHYBAR_LOG"
    run_plugin routine '' 1000 || failed=1
    assert_file_contains "$SKETCHYBAR_LOG" 'label=off' 'invalid numeric state falls back to idle' || failed=1

    write_state running focus 1200 0
    : > "$SKETCHYBAR_LOG"
    run_plugin routine '' 1000 || failed=1
    assert_file_contains "$SKETCHYBAR_LOG" 'label=off' 'invalid mode falls back to idle' || failed=1

    [ "$failed" -eq 0 ] && pass 'invalid inputs are harmless and click semantics are preserved'
}

test_static_state_safety
test_valid_states
test_default_state_home
test_permissions_and_atomic_write
test_rejects_unsafe_state_paths
test_failed_saves_never_publish_transitions
test_signal_cleans_active_tempfile_before_locks
test_invalid_date_is_safe
test_lock_file_safety_and_shlock_requirement
test_shlock_serializes_and_recovers_sigkill_holder
test_notification_does_not_hold_locks
test_concurrent_expiry_stress
test_corrupt_state_is_inert_and_idle
test_restart_and_expiry
test_pause_resume_uses_explicit_remaining_time
test_invalid_inputs_and_click_semantics

printf '%s passed, %s failed\n' "$PASS_COUNT" "$FAIL_COUNT"
[ "$FAIL_COUNT" -eq 0 ]
