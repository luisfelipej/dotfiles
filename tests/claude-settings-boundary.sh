#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR=$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)
SETTINGS_EXAMPLE="$ROOT_DIR/claude/.claude/settings.example.json"
TMP_DIR=$(mktemp -d)
trap 'rm -rf "$TMP_DIR"' EXIT

fail() {
    printf 'FAIL: %s\n' "$1" >&2
    exit 1
}

if [ -e "$ROOT_DIR/claude/.claude/settings.json" ] || \
    [ -L "$ROOT_DIR/claude/.claude/settings.json" ]; then
    fail 'the Claude package still manages the user settings file'
fi

python3 -m json.tool "$SETTINGS_EXAMPLE" >/dev/null || \
    fail 'the portable settings example is not valid JSON'

if grep -Eq '(/Users/[^/]+|/home/[^/]+)' "$SETTINGS_EXAMPLE"; then
    fail 'the portable settings example contains an absolute user path'
fi

python3 - "$SETTINGS_EXAMPLE" <<'PY'
import json
import sys

with open(sys.argv[1], encoding="utf-8") as settings_file:
    settings = json.load(settings_file)

expected = "bash ~/.claude/statusline-command.sh"
actual = settings.get("statusLine", {}).get("command")
if actual != expected:
    raise SystemExit(
        f"FAIL: portable status line command is {actual!r}, expected {expected!r}"
    )

PY

LOCAL_HOME="$TMP_DIR/local-home"
mkdir -p "$LOCAL_HOME/.claude"
printf '{"theme":"dark"}\n' > "$LOCAL_HOME/.claude/settings.json"
printf 'local session state\n' > "$LOCAL_HOME/.claude/history.jsonl"

HOME="$LOCAL_HOME" STOW_DIR="$ROOT_DIR" \
    /bin/bash "$ROOT_DIR/stow.sh" restow claude >/dev/null || \
    fail 'Claude restow conflicts with supported local user settings'

[ ! -L "$LOCAL_HOME/.claude" ] || \
    fail 'Claude restow folded the local state directory into the repository'
[ "$(cat "$LOCAL_HOME/.claude/settings.json")" = '{"theme":"dark"}' ] || \
    fail 'Claude restow changed local user settings'
[ "$(cat "$LOCAL_HOME/.claude/history.jsonl")" = 'local session state' ] || \
    fail 'Claude restow changed local session state'
[ ! -e "$ROOT_DIR/claude/.claude/history.jsonl" ] || \
    fail 'local session state leaked into the repository'

HOME="$LOCAL_HOME" STOW_DIR="$ROOT_DIR" \
    /bin/bash "$ROOT_DIR/stow.sh" unstow claude >/dev/null || \
    fail 'Claude unstow rejected regular local user settings'
[ -f "$LOCAL_HOME/.claude/settings.json" ] && \
    [ ! -L "$LOCAL_HOME/.claude/settings.json" ] && \
    [ "$(cat "$LOCAL_HOME/.claude/settings.json")" = '{"theme":"dark"}' ] || \
    fail 'Claude unstow changed regular local user settings'

LEGACY_HOME="$TMP_DIR/legacy-home"
mkdir -p "$LEGACY_HOME/.claude"
ln -s "$ROOT_DIR" "$LEGACY_HOME/.dotfiles"
ln -s '../.dotfiles/claude/.claude/settings.json' \
    "$LEGACY_HOME/.claude/settings.json"
HOME="$LEGACY_HOME" STOW_DIR="$LEGACY_HOME/.dotfiles" \
    /bin/bash "$ROOT_DIR/stow.sh" restow claude >/dev/null || \
    fail 'Claude restow failed to migrate legacy user settings'

[ -f "$LEGACY_HOME/.claude/settings.json" ] && \
    [ ! -L "$LEGACY_HOME/.claude/settings.json" ] || \
    fail 'legacy dangling user settings were not migrated to a regular file'
cmp -s "$SETTINGS_EXAMPLE" "$LEGACY_HOME/.claude/settings.json" || \
    fail 'migrated user settings do not match the portable example'

LEGACY_UNSTOW_HOME="$TMP_DIR/legacy-unstow-home"
mkdir -p "$LEGACY_UNSTOW_HOME/.claude"
ln -s "$ROOT_DIR" "$LEGACY_UNSTOW_HOME/.dotfiles"
ln -s '../.dotfiles/claude/.claude/settings.json' \
    "$LEGACY_UNSTOW_HOME/.claude/settings.json"
HOME="$LEGACY_UNSTOW_HOME" STOW_DIR="$LEGACY_UNSTOW_HOME/.dotfiles" \
    /bin/bash "$ROOT_DIR/stow.sh" unstow claude >/dev/null || \
    fail 'Claude unstow failed to remove legacy user settings'

[ ! -e "$LEGACY_UNSTOW_HOME/.claude/settings.json" ] && \
    [ ! -L "$LEGACY_UNSTOW_HOME/.claude/settings.json" ] || \
    fail 'Claude unstow created settings while removing the legacy link'

VALID_HOME="$TMP_DIR/valid-link-home"
mkdir -p "$VALID_HOME/.claude" "$VALID_HOME/local"
printf '{"theme":"light"}\n' > "$VALID_HOME/local/settings.json"
ln -s "$VALID_HOME/local/settings.json" "$VALID_HOME/.claude/settings.json"
HOME="$VALID_HOME" STOW_DIR="$ROOT_DIR" \
    /bin/bash "$ROOT_DIR/stow.sh" restow claude >/dev/null || \
    fail 'Claude restow rejected a valid local settings symlink'

[ -L "$VALID_HOME/.claude/settings.json" ] && \
    [ "$(readlink "$VALID_HOME/.claude/settings.json")" = "$VALID_HOME/local/settings.json" ] || \
    fail 'Claude restow changed a valid local settings symlink'
HOME="$VALID_HOME" STOW_DIR="$ROOT_DIR" \
    /bin/bash "$ROOT_DIR/stow.sh" unstow claude >/dev/null || \
    fail 'Claude unstow rejected a valid local settings symlink'
[ -L "$VALID_HOME/.claude/settings.json" ] && \
    [ "$(readlink "$VALID_HOME/.claude/settings.json")" = "$VALID_HOME/local/settings.json" ] || \
    fail 'Claude unstow changed a valid local settings symlink'

FOREIGN_HOME="$TMP_DIR/foreign-link-home"
mkdir -p "$FOREIGN_HOME/.claude"
ln -s '../missing/settings.json' "$FOREIGN_HOME/.claude/settings.json"
HOME="$FOREIGN_HOME" STOW_DIR="$ROOT_DIR" \
    /bin/bash "$ROOT_DIR/stow.sh" restow claude >/dev/null || \
    fail 'Claude restow rejected a foreign dangling settings symlink'

[ -L "$FOREIGN_HOME/.claude/settings.json" ] && \
    [ "$(readlink "$FOREIGN_HOME/.claude/settings.json")" = '../missing/settings.json' ] || \
    fail 'Claude restow changed a foreign dangling settings symlink'
HOME="$FOREIGN_HOME" STOW_DIR="$ROOT_DIR" \
    /bin/bash "$ROOT_DIR/stow.sh" unstow claude >/dev/null || \
    fail 'Claude unstow rejected a foreign dangling settings symlink'
[ -L "$FOREIGN_HOME/.claude/settings.json" ] && \
    [ "$(readlink "$FOREIGN_HOME/.claude/settings.json")" = '../missing/settings.json' ] || \
    fail 'Claude unstow changed a foreign dangling settings symlink'

FOLDED_REPO="$TMP_DIR/folded repo"
mkdir -p "$FOLDED_REPO/claude/.claude"
printf '.credentials.json\n' > "$FOLDED_REPO/claude/.claude/.gitignore"
printf 'managed fixture\n' > "$FOLDED_REPO/claude/.claude/managed.txt"
cp "$SETTINGS_EXAMPLE" "$FOLDED_REPO/claude/.claude/settings.example.json"
git -C "$FOLDED_REPO" init -q
git -C "$FOLDED_REPO" add claude
git -C "$FOLDED_REPO" \
    -c user.name='Test User' \
    -c user.email='test@example.com' \
    commit -qm 'test fixture'

FOLDED_HOME="$TMP_DIR/folded-home"
mkdir -p "$FOLDED_HOME"
stow --dir="$FOLDED_REPO" --target="$FOLDED_HOME" claude
mkdir -p "$FOLDED_HOME/.claude/runtime state/Session One"
printf 'ignored credential bytes\n' > "$FOLDED_HOME/.claude/.credentials.json"
printf 'untracked history bytes\n' > \
    "$FOLDED_HOME/.claude/runtime state/Session One/history file.jsonl"

HOME="$FOLDED_HOME" STOW_DIR="$FOLDED_REPO" \
    /bin/bash "$ROOT_DIR/stow.sh" restow claude >/dev/null || \
    fail 'Claude restow failed to migrate a previously folded directory'

[ -d "$FOLDED_HOME/.claude" ] && [ ! -L "$FOLDED_HOME/.claude" ] || \
    fail 'Claude restow left a previously folded state directory in place'
[ "$(cat "$FOLDED_HOME/.claude/.credentials.json")" = \
    'ignored credential bytes' ] || \
    fail 'Claude restow lost ignored credential state'
[ "$(cat "$FOLDED_HOME/.claude/runtime state/Session One/history file.jsonl")" = \
    'untracked history bytes' ] || \
    fail 'Claude restow lost untracked state with spaces in its path'
[ ! -e "$FOLDED_REPO/claude/.claude/.credentials.json" ] && \
    [ ! -e "$FOLDED_REPO/claude/.claude/runtime state" ] || \
    fail 'Claude restow left local state inside the repository'
[ -L "$FOLDED_HOME/.claude/managed.txt" ] || \
    fail 'Claude restow did not link the tracked managed file as a leaf'

UNSTOW_HOME="$TMP_DIR/unstow-home"
mkdir -p "$UNSTOW_HOME"
stow --dir="$FOLDED_REPO" --target="$UNSTOW_HOME" claude
mkdir -p "$UNSTOW_HOME/.claude/runtime state/Session Two"
printf 'unstow credential bytes\n' > "$UNSTOW_HOME/.claude/.credentials.json"
printf 'unstow history bytes\n' > \
    "$UNSTOW_HOME/.claude/runtime state/Session Two/history file.jsonl"

HOME="$UNSTOW_HOME" STOW_DIR="$FOLDED_REPO" \
    /bin/bash "$ROOT_DIR/stow.sh" unstow claude >/dev/null || \
    fail 'Claude unstow failed to migrate a previously folded directory'

[ -d "$UNSTOW_HOME/.claude" ] && [ ! -L "$UNSTOW_HOME/.claude" ] || \
    fail 'Claude unstow hid the migrated local state directory'
[ "$(cat "$UNSTOW_HOME/.claude/.credentials.json")" = \
    'unstow credential bytes' ] || \
    fail 'Claude unstow lost ignored credential state'
[ "$(cat "$UNSTOW_HOME/.claude/runtime state/Session Two/history file.jsonl")" = \
    'unstow history bytes' ] || \
    fail 'Claude unstow lost untracked state with spaces in its path'
[ ! -e "$FOLDED_REPO/claude/.claude/.credentials.json" ] && \
    [ ! -e "$FOLDED_REPO/claude/.claude/runtime state" ] || \
    fail 'Claude unstow left local state inside the repository'
[ ! -e "$UNSTOW_HOME/.claude/managed.txt" ] && \
    [ ! -L "$UNSTOW_HOME/.claude/managed.txt" ] || \
    fail 'Claude unstow kept a managed file linked'

MISSING_UNSTOW_HOME="$TMP_DIR/missing-unstow-home"
mkdir -p "$MISSING_UNSTOW_HOME"
HOME="$MISSING_UNSTOW_HOME" STOW_DIR="$FOLDED_REPO" \
    /bin/bash "$ROOT_DIR/stow.sh" unstow claude >/dev/null || \
    fail 'Claude unstow failed with no target directory'
[ ! -e "$MISSING_UNSTOW_HOME/.claude" ] && \
    [ ! -L "$MISSING_UNSTOW_HOME/.claude" ] || \
    fail 'Claude unstow created a missing local state directory'

NO_GIT_REPO="$TMP_DIR/no-git-repo"
NO_GIT_HOME="$TMP_DIR/no-git-home"
mkdir -p "$NO_GIT_REPO/claude/.claude" "$NO_GIT_HOME"
printf 'managed fixture\n' > "$NO_GIT_REPO/claude/.claude/managed.txt"
stow --dir="$NO_GIT_REPO" --target="$NO_GIT_HOME" claude
printf 'unclassified state bytes\n' > "$NO_GIT_HOME/.claude/history.jsonl"

if HOME="$NO_GIT_HOME" STOW_DIR="$NO_GIT_REPO" \
    /bin/bash "$ROOT_DIR/stow.sh" restow claude >/dev/null 2>&1; then
    fail 'Claude restow migrated folded state without Git classification'
fi
[ -L "$NO_GIT_HOME/.claude" ] || \
    fail 'failed Git classification changed the folded directory'
[ "$(cat "$NO_GIT_REPO/claude/.claude/history.jsonl")" = \
    'unclassified state bytes' ] || \
    fail 'failed Git classification changed local state bytes'

FRESH_HOME="$TMP_DIR/fresh-home"
mkdir -p "$FRESH_HOME"
HOME="$FRESH_HOME" STOW_DIR="$ROOT_DIR" \
    /bin/bash "$ROOT_DIR/stow.sh" restow claude >/dev/null || \
    fail 'Claude restow failed in a fresh home'

[ -d "$FRESH_HOME/.claude" ] && [ ! -L "$FRESH_HOME/.claude" ] || \
    fail 'fresh Claude restow exposed the repository as the local state directory'
[ ! -e "$FRESH_HOME/.claude/settings.json" ] && \
    [ ! -L "$FRESH_HOME/.claude/settings.json" ] || \
    fail 'fresh Claude restow installed user settings implicitly'

python3 - "$SETTINGS_EXAMPLE" <<'PY'
import json
import sys

with open(sys.argv[1], encoding="utf-8") as settings_file:
    settings = json.load(settings_file)

expected = [
    "Read(./.env)",
    "Read(./.env.*)",
    "Edit(./.env)",
    "Edit(./.env.*)",
]
actual = settings.get("permissions", {}).get("deny")
if actual != expected:
    raise SystemExit(
        f"FAIL: portable .env deny rules are {actual!r}, expected {expected!r}"
    )
PY

printf 'PASS: Claude settings and runtime state remain machine-local\n'
