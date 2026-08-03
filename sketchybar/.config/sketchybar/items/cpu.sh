#!/usr/bin/env zsh
# cpu — right; plugins/cpu.sh on 5s timer

sketchybar --add item cpu right \
    --set cpu \
    update_freq=5 \
    script="$PLUGIN_DIR/cpu.sh"
