#!/usr/bin/env bash
set -euo pipefail
DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$DIR/generate.sh"
THEMES="$DIR/../themes"
fail=0
check() { # check NAME ACTUAL EXPECTED
  if [ "$2" = "$3" ]; then echo "ok - $1"; else echo "FAIL - $1: got [$2] want [$3]"; fail=1; fi
}

# --- parser ---
check "accent gruvbox" "$(manifest_get "$THEMES/gruvbox-material.toml" palette accent)" "e78a4e"
check "native ghostty gruvbox" "$(manifest_get "$THEMES/gruvbox-material.toml" native ghostty)" "Gruvbox Material Dark"
check "bg tokyo" "$(manifest_get "$THEMES/tokyo-night.toml" palette bg)" "1a1b26"
check "absent key" "$(manifest_get "$THEMES/gruvbox-material.toml" palette nope)" ""

load_palette "$THEMES/gruvbox-material.toml"
check "load_palette bg" "$bg" "282828"
check "load_palette accent" "$accent" "e78a4e"

# --- fragment golden tests ---
gen_check() { # gen_check THEME APP GENFN [GENARG]
  local theme=$1 app=$2 fn=$3 arg=${4:-}
  load_palette "$THEMES/$theme.toml"
  local got want
  got="$($fn "$arg")"
  want="$(cat "$DIR/golden/$theme/$app")"
  if [ "$got" = "$want" ]; then echo "ok - $app $theme"; else
    echo "FAIL - $app $theme:"; diff <(echo "$want") <(echo "$got") | sed 's/^/    /'; fail=1; fi
}

gen_check gruvbox-material sketchybar.sh gen_sketchybar
gen_check tokyo-night     sketchybar.sh gen_sketchybar

gen_check gruvbox-material borders.env gen_borders
gen_check tokyo-night     borders.env gen_borders

exit $fail
