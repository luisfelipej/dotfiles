#!/usr/bin/env bash
# appearance — runs when macOS switches light/dark. colors.sh and bordersrc
# read the current appearance themselves, so running them again is enough.

[ "$SENDER" = "appearance_changed" ] || exit 0

bash "$HOME/.config/borders/bordersrc"
sketchybar --reload
