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

gen_check gruvbox-material ghostty.conf gen_ghostty "$THEMES/gruvbox-material.toml"
gen_check tokyo-night     ghostty.conf gen_ghostty "$THEMES/tokyo-night.toml"

gen_check gruvbox-material lazygit.yml gen_lazygit
gen_check tokyo-night     lazygit.yml gen_lazygit

gen_check gruvbox-material nvim gen_nvim "$THEMES/gruvbox-material.toml"
gen_check tokyo-night     nvim gen_nvim "$THEMES/tokyo-night.toml"

gen_check gruvbox-material btop.theme gen_btop "Gruvbox Material"
gen_check tokyo-night     btop.theme gen_btop "Tokyo Night"

# gen_starship: the active palette line is rewritten, palettes preserved
base="$THEMES/../../../../starship/.config/starship.toml"
if [ -f "$base" ]; then
  out="$(gen_starship "$base" tokyo-night)"
  check "starship palette switched" "$(echo "$out" | grep -m1 '^palette =')" 'palette = "tokyo-night"'
  check "starship keeps gruvbox palette def" "$(echo "$out" | grep -c '\[palettes.gruvbox-material\]')" "1"
fi

# --- idempotency: generating twice is byte-identical ---
for theme in gruvbox-material tokyo-night; do
  load_palette "$THEMES/$theme.toml"
  a="$(gen_sketchybar)"; b="$(gen_sketchybar)"
  check "idempotent sketchybar $theme" "$a" "$b"
done

# --- shell fragments parse with bash -n ---
load_palette "$THEMES/gruvbox-material.toml"
if gen_sketchybar | bash -n; then echo "ok - sketchybar.sh valid shell"; else echo "FAIL - sketchybar.sh invalid"; fail=1; fi
if gen_borders | bash -n; then echo "ok - borders.env valid shell"; else echo "FAIL - borders.env invalid"; fail=1; fi

exit $fail
