#!/usr/bin/env zsh
# memory — right; plugins/memory.sh on 10s timer

sketchybar --add item memory right \
    --set memory \
    update_freq=10 \
    script="$PLUGIN_DIR/memory.sh"
