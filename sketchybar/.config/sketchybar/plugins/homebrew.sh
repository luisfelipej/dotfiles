#!/usr/bin/env bash
# homebrew — outdated package count + popup list; 5m timer + brew_update event

source "$CONFIG_DIR/colors.sh"

export PATH="/opt/homebrew/bin:/usr/bin:/bin:/usr/sbin:$PATH"
export HOMEBREW_NO_ENV_HINTS=1
BREW=/opt/homebrew/bin/brew

# launchd sets SIGCHLD to SIG_IGN, which makes `brew outdated` crash while
# version-checking auto-updating casks. Run brew via a perl wrapper that resets
# SIGCHLD to default first.
brew_safe() { /usr/bin/perl -e '$SIG{CHLD}="DEFAULT"; exec @ARGV' "$BREW" "$@"; }

# Refresh the catalog at most every 10 min so `brew outdated` sees new versions.
STAMP="${HOME}/.cache/sketchybar/brew_update.stamp"
mkdir -p "$(dirname "$STAMP")"
if [ ! -f "$STAMP" ] || [ -n "$(find "$STAMP" -mmin +10 2>/dev/null)" ]; then
  brew_safe update --quiet >/dev/null 2>&1
  touch "$STAMP"
fi

PINNED=$(HOMEBREW_NO_AUTO_UPDATE=1 brew_safe list --pinned --quiet 2>/dev/null)
if [ -n "$PINNED" ]; then
  OUTDATED=$(HOMEBREW_NO_AUTO_UPDATE=1 brew_safe outdated --quiet 2>/dev/null | grep -vxF "$PINNED")
else
  OUTDATED=$(HOMEBREW_NO_AUTO_UPDATE=1 brew_safe outdated --quiet 2>/dev/null)
fi

COUNT=$(echo "$OUTDATED" | grep -c .)

case "${COUNT}" in
  [3-9][0-9]|[1-9][0-9][0-9]) COLOR=$RED ;;
  [1-2][0-9]) COLOR=$ORANGE ;;
  [1-9]) COLOR=$YELLOW ;;
  *) COLOR=$FG ;;
esac

if [ "$COUNT" -eq 0 ]; then
  sketchybar --set "$NAME" drawing=off
  sketchybar --remove '/homebrew.pkg\..*/' 2>/dev/null
  exit 0
fi

sketchybar --set "$NAME" drawing=on icon= label="$COUNT" icon.color="$COLOR" label.color="$COLOR"

# Rebuild popup list
sketchybar --remove '/homebrew.pkg\..*/' 2>/dev/null
INDEX=0
while IFS= read -r pkg; do
  [ -z "$pkg" ] && continue
  sketchybar --add item "homebrew.pkg.$INDEX" popup.homebrew \
    --set "homebrew.pkg.$INDEX" \
    icon= \
    icon.color=$YELLOW \
    icon.font="$FONT:Bold:14.0" \
    icon.padding_left=10 \
    label="$pkg" \
    label.font="$FONT:Regular:13.0" \
    label.color=$FG \
    label.padding_right=10
  INDEX=$((INDEX + 1))
done <<< "$OUTDATED"
