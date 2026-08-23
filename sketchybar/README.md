# SketchyBar configuration

## Pomodoro state

The Pomodoro plugin stores state at
`${XDG_STATE_HOME:-$HOME/.local/state}/sketchybar/pomodoro.state`. It does not
read or migrate the former `/tmp/sketchybar_pomodoro` file.

The state directory is mode `0700`, and the state file is mode `0600`. Updates
are written to a temporary file in the same directory and atomically renamed
over the previous state. The plugin rejects either path when the exact state
directory is a symlink or non-directory, or when the exact state file is a
symlink or non-regular file. It never follows those paths to external targets.
Persisted data uses a strict, non-executable format:

```text
version=1
state=running
mode=work
deadline=1787500000
remaining=0
```

`deadline` is an epoch timestamp for a running session. The parser still accepts
previously persisted `paused` records, but the plugin no longer creates them;
the next primary click resets them to idle. Invalid or corrupt data is treated
as idle. Clock output is validated before arithmetic.

Invocations are serialized by the native macOS `/usr/bin/shlock` utility using
the private `${XDG_STATE_HOME:-$HOME/.local/state}/sketchybar/.pomodoro.lock`
file. `shlock` uses `link(2)`, validates the owner PID, and atomically replaces
stale locks. The plugin rejects a lock path that is a symlink or non-regular
file and enforces mode `0600` after acquisition.

`/usr/bin/shlock` must be present and executable. If it is unavailable or the
lock cannot be acquired safely, the invocation exits without changing state,
UI, or notifications.

Signal cleanup removes only the tracked regular tempfile in the state directory
before releasing the owned lock file. State transitions and notifications are
published only after the atomic state write succeeds. The lock is released
after rendering and before invoking `osascript`, so a slow notification cannot
block later updates.

Right-click resets the timer. Any other mouse button is the primary action: it
starts a work timer from idle and resets running or legacy paused state.

Run the focused test suite with:

```sh
sketchybar/tests/pomodoro_test.sh
```
