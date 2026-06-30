#!/usr/bin/env bash
# generate.sh — render a theme manifest into per-app fragments.
# Sourced by theme-set; functions write fragments to stdout.

# manifest_get FILE SECTION KEY -> value (quotes stripped). Empty if absent.
manifest_get() {
  local file=$1 section=$2 key=$3
  awk -v want="[$section]" -v key="$key" '
    $0 == want { ins=1; next }
    /^\[/      { ins=0 }
    ins {
      line=$0
      sub(/[ \t]*#.*$/, "", line)
      if (line ~ ("^[ \t]*" key "[ \t]*=")) {
        sub(/^[^=]*=[ \t]*/, "", line)
        gsub(/^[ \t]*"|"[ \t]*$/, "", line)
        print line
        exit
      }
    }
  ' "$file"
}

# load_palette MANIFEST -> sets palette role globals
load_palette() {
  local m=$1
  bg=$(manifest_get "$m" palette bg)
  bg_alt=$(manifest_get "$m" palette bg_alt)
  bg_secondary=$(manifest_get "$m" palette bg_secondary)
  bg_overlay=$(manifest_get "$m" palette bg_overlay)
  bg_selection=$(manifest_get "$m" palette bg_selection)
  fg=$(manifest_get "$m" palette fg)
  fg_muted=$(manifest_get "$m" palette fg_muted)
  red=$(manifest_get "$m" palette red)
  orange=$(manifest_get "$m" palette orange)
  yellow=$(manifest_get "$m" palette yellow)
  green=$(manifest_get "$m" palette green)
  aqua=$(manifest_get "$m" palette aqua)
  blue=$(manifest_get "$m" palette blue)
  purple=$(manifest_get "$m" palette purple)
  accent=$(manifest_get "$m" palette accent)
}
