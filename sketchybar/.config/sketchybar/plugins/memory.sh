#!/usr/bin/env bash
# memory — used-memory % from vm_stat, color-coded; 10s timer

source "$CONFIG_DIR/colors.sh"

TOTAL_MEM_MB=$(($(sysctl -n hw.memsize) / 1024 / 1024))
PAGE_SIZE=$(sysctl -n hw.pagesize)
VM_STAT=$(vm_stat)

ACTIVE=$(echo "$VM_STAT" | awk '/Pages active/ {gsub(/\./, "", $3); print $3}')
WIRED=$(echo "$VM_STAT" | awk '/Pages wired/ {gsub(/\./, "", $4); print $4}')
COMPRESSED=$(echo "$VM_STAT" | awk '/Pages occupied by compressor/ {gsub(/\./, "", $5); print $5}')

USED_MB=$(( (ACTIVE + WIRED + COMPRESSED) * PAGE_SIZE / 1024 / 1024 ))
MEM_PERCENT=$(( USED_MB * 100 / TOTAL_MEM_MB ))

COLOR=$(color_for_value "$MEM_PERCENT" 90 $RED 70 $ORANGE 50 $YELLOW 0 $GREEN)

sketchybar --set "$NAME" \
  icon="󱤓" \
  label="${MEM_PERCENT}%" \
  icon.color="$COLOR" \
  label.color="$COLOR"
