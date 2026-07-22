#!/usr/bin/env zsh
# Kanagawa Wave palette — sketchybar uses 0xAARRGGBB

export BAR_COLOR=0xff1f1f28
export BAR_BORDER_COLOR=0xff363646

export BG_PRIMARY=0xff2a2a37
export BG_SECONDARY=0xff363646
export BG_OVERLAY=0xff54546d
export BG_TRANSPARENT=0x00000000

export FG=0xffdcd7ba
export FG_MUTED=0xff727169
export FG_DIM=0x66727169

export RED=0xffe46876
export ORANGE=0xffffa066
export YELLOW=0xffe6c384
export GREEN=0xff98bb6c
export AQUA=0xff7aa89f
export BLUE=0xff7e9cd8
export PURPLE=0xff957fb8

# Semantic aliases
export ACCENT=$BLUE
export SPACE_ACTIVE=$BLUE
export SPACE_INACTIVE=$FG_MUTED
export BATTERY_OK=$GREEN
export BATTERY_LOW=$RED
export CPU_BG=$ACCENT
export CALENDAR=$YELLOW
export WIFI=$AQUA
export CLOCK_FG=$YELLOW
export WEATHER_FG=$AQUA
export VOLUME_FG=$BLUE
export POMODORO_FG=$FG

# Font for ported plugins
export FONT="JetBrainsMono Nerd Font"

# New-widget semantic roles (reuse Kanagawa base colors)
export WIFI_OK=$GREEN
export WIFI_OFF=$RED
export BRIGHTNESS_FG=$YELLOW

# Opaque popup styling (apple / homebrew menus)
export POPUP_BG=$BG_PRIMARY
export POPUP_BORDER=$BG_OVERLAY

# color_for_value VALUE T1 COLOR1 T2 COLOR2 ... DEFAULT_COLOR
# Thresholds descending; returns first COLOR where VALUE >= threshold.
color_for_value() {
  local value=$1; shift
  while [ $# -gt 1 ]; do
    local threshold=$1 color=$2; shift 2
    if [ "$value" -ge "$threshold" ]; then echo "$color"; return; fi
  done
  echo "$1"
}
