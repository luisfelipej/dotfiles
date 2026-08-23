#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR=$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)
TMP_DIR=$(mktemp -d)
trap 'rm -rf "$TMP_DIR"' EXIT

REPO_DIR="$TMP_DIR/repo"
HOME_DIR="$TMP_DIR/home"
mkdir -p "$REPO_DIR/first" "$REPO_DIR/second" "$HOME_DIR"
printf 'first repository file\n' > "$REPO_DIR/first/.first"
printf 'second repository file\n' > "$REPO_DIR/second/.second"
printf 'existing home file\n' > "$HOME_DIR/.second"

BASH32_REPO="$TMP_DIR/bash32-repo"
BASH32_HOME="$TMP_DIR/bash32-home"
mkdir -p "$BASH32_REPO/package" "$BASH32_HOME"
printf 'bash 3.2 repository file\n' > "$BASH32_REPO/package/.bash32"
HOME="$BASH32_HOME" STOW_DIR="$BASH32_REPO" \
    /bin/bash "$ROOT_DIR/stow.sh" stow package >/dev/null
if [ ! -L "$BASH32_HOME/.bash32" ]; then
    printf 'FAIL: stow mode did not run under Bash 3.2\n' >&2
    exit 1
fi

if HOME="$HOME_DIR" make --no-print-directory \
    -C "$REPO_DIR" \
    -f "$ROOT_DIR/Makefile" \
    PACKAGES='first second' \
    restow >"$TMP_DIR/output" 2>&1; then
    printf 'FAIL: restow unexpectedly succeeded with a conflict\n' >&2
    exit 1
fi

if [ -e "$HOME_DIR/.first" ] || [ -L "$HOME_DIR/.first" ]; then
    printf 'FAIL: the first package was partially applied\n' >&2
    exit 1
fi

if [ "$(cat "$HOME_DIR/.second")" != 'existing home file' ]; then
    printf 'FAIL: the conflicting home file changed\n' >&2
    exit 1
fi

if [ "$(cat "$REPO_DIR/second/.second")" != 'second repository file' ]; then
    printf 'FAIL: the conflicting file was adopted into the repository\n' >&2
    exit 1
fi

rm "$HOME_DIR/.second"
if HOME="$HOME_DIR" STOW_PREFLIGHT_ONLY=1 make --no-print-directory \
    -C "$REPO_DIR" \
    -f "$ROOT_DIR/Makefile" \
    PACKAGES='first second' \
    restow >/dev/null; then
    if [ -e "$HOME_DIR/.first" ] || [ -L "$HOME_DIR/.first" ]; then
        printf 'FAIL: preflight-only mode applied package changes\n' >&2
        exit 1
    fi
else
    printf 'FAIL: preflight-only mode rejected conflict-free packages\n' >&2
    exit 1
fi

HOME="$HOME_DIR" make --no-print-directory \
    -C "$REPO_DIR" \
    -f "$ROOT_DIR/Makefile" \
    PACKAGES='first second' \
    restow >/dev/null

if [ ! -L "$HOME_DIR/.first" ] || [ ! -L "$HOME_DIR/.second" ]; then
    printf 'FAIL: conflict-free packages were not stowed\n' >&2
    exit 1
fi

HOME="$HOME_DIR" make --no-print-directory \
    -C "$REPO_DIR" \
    -f "$ROOT_DIR/Makefile" \
    PACKAGES='first second' \
    unstow >/dev/null

git -C "$REPO_DIR" init -q
git -C "$REPO_DIR" add first second
git -C "$REPO_DIR" \
    -c user.name='Test User' \
    -c user.email='test@example.com' \
    commit -qm 'test fixture'
printf 'existing home file\n' > "$HOME_DIR/.second"

BACKUP="$TMP_DIR/adopt-backup.tar.gz"
if HOME="$HOME_DIR" \
    STOW_ADOPT_BACKUP="$BACKUP" \
    STOW_ADOPT_CONFIRM=cancel \
    make --no-print-directory \
        -C "$REPO_DIR" \
        -f "$ROOT_DIR/Makefile" \
        PACKAGES='first second' \
        adopt >/dev/null 2>&1; then
    printf 'FAIL: adoption accepted an invalid confirmation\n' >&2
    exit 1
fi
if [ -e "$BACKUP" ] || [ "$(cat "$REPO_DIR/second/.second")" != 'second repository file' ]; then
    printf 'FAIL: cancelled adoption changed files\n' >&2
    exit 1
fi

HOME="$HOME_DIR" \
STOW_ADOPT_BACKUP="$BACKUP" \
STOW_ADOPT_CONFIRM=adopt \
make --no-print-directory \
    -C "$REPO_DIR" \
    -f "$ROOT_DIR/Makefile" \
    PACKAGES='first second' \
    adopt >/dev/null

if [ "$(cat "$REPO_DIR/second/.second")" != 'existing home file' ]; then
    printf 'FAIL: explicit adoption did not update the repository\n' >&2
    exit 1
fi

HOME="$HOME_DIR" make --no-print-directory \
    -C "$REPO_DIR" \
    -f "$ROOT_DIR/Makefile" \
    PACKAGES='first second' \
    unstow >/dev/null
git -C "$REPO_DIR" restore --worktree -- first second
tar -xzf "$BACKUP" -C "$HOME_DIR"

if [ -L "$HOME_DIR/.second" ] || [ "$(cat "$HOME_DIR/.second")" != 'existing home file' ]; then
    printf 'FAIL: recovery did not restore the original home file\n' >&2
    exit 1
fi
if [ "$(cat "$REPO_DIR/second/.second")" != 'second repository file' ]; then
    printf 'FAIL: recovery did not restore the repository file\n' >&2
    exit 1
fi

printf 'PASS: global preflight prevents partial stow changes\n'
printf 'PASS: explicit adoption creates a recoverable backup\n'
