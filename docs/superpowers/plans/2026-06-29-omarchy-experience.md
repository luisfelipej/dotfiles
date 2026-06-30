# Omarchy-style Experience Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Add a unified, single-source theming system to the macOS dotfiles (seeded with Gruvbox Material + Tokyo Night), standardize on CaskaydiaMono Nerd Font, and add the TUIs Omarchy takes for granted.

**Architecture:** One TOML manifest per theme is the single source of truth for the palette. A bash generator renders per-app fragments into a gitignored state dir (`~/.local/state/theme/`); each app sources/reads from there, so switching themes never dirties git. A `theme-set` script applies a theme (generate + reload). Seed themes prove real switching.

**Tech Stack:** bash (generator + scripts), GNU Stow, fish, AeroSpace, SketchyBar, JankyBorders, Ghostty, lazygit, btop, starship, Neovim/LazyVim, Homebrew.

## Global Constraints

- Platform: macOS (darwin); interactive shell is fish; configs managed by GNU Stow.
- **Generated output MUST live under `${XDG_STATE_HOME:-$HOME/.local/state}/theme/` (gitignored). Switching a theme must leave `git status` clean.** The one exception is btop's `current.theme`, which lives in a `--no-folding` real dir and is gitignored explicitly.
- Dotfiles repo root is `$HOME/.dotfiles` (per README clone path); scripts may assume it.
- Color values in manifests are bare lowercase `rrggbb` hex (no `#`, no `0x`). Generators add the per-app prefix.
- Seed themes: exactly `gruvbox-material` and `tokyo-night`.
- Standard font everywhere it is configurable: `CaskaydiaMono Nerd Font` (mono variant where required).
- Generator/scripts in bash; invoked from fish via `~/.local/bin` on PATH.
- Manifest sections are `[theme]`, `[palette]`, `[native]`. No top-level keys.
- Follow conventional-commit style (repo uses `feat:`/`fix:`/`docs:` with optional scope).

---

### Task 1: Theme package skeleton, manifests, and manifest parser

**Files:**
- Create: `theme/.config/theme/themes/gruvbox-material.toml`
- Create: `theme/.config/theme/themes/tokyo-night.toml`
- Create: `theme/.config/theme/lib/generate.sh`
- Create: `theme/.config/theme/lib/test.sh`

**Interfaces:**
- Produces: `manifest_get FILE SECTION KEY` → prints the value (quotes stripped, empty if absent). `load_palette MANIFEST` → sets globals `bg bg_alt bg_secondary bg_overlay bg_selection fg fg_muted red orange yellow green aqua blue purple accent`.

- [ ] **Step 1: Create the Gruvbox manifest**

`theme/.config/theme/themes/gruvbox-material.toml`:
```toml
[theme]
name = "gruvbox-material"
wallpaper = "gruvbox_astro.jpg"

[palette]
bg           = "282828"
bg_alt       = "32302f"
bg_secondary = "3a3735"
bg_overlay   = "504945"
bg_selection = "665c54"
fg           = "d4be98"
fg_muted     = "a89984"
red          = "ea6962"
orange       = "e78a4e"
yellow       = "d8a657"
green        = "a9b665"
aqua         = "89b482"
blue         = "7daea3"
purple       = "d3869b"
accent       = "e78a4e"

[native]
ghostty = "Gruvbox Material Dark"
nvim    = "gruvbox-material"
```

- [ ] **Step 2: Create the Tokyo Night manifest**

`theme/.config/theme/themes/tokyo-night.toml`:
```toml
[theme]
name = "tokyo-night"
wallpaper = ""

[palette]
bg           = "1a1b26"
bg_alt       = "16161e"
bg_secondary = "24283b"
bg_overlay   = "414868"
bg_selection = "33467c"
fg           = "c0caf5"
fg_muted     = "565f89"
red          = "f7768e"
orange       = "ff9e64"
yellow       = "e0af68"
green        = "9ece6a"
aqua         = "7dcfff"
blue         = "7aa2f7"
purple       = "bb9af7"
accent       = "7aa2f7"

[native]
ghostty = "TokyoNight"
nvim    = "tokyonight"
```

(Note: `wallpaper = ""` means theme-set skips wallpaper for this theme. The user can drop a tokyo-night image into `wallpapers/` and set the name later. The exact ghostty built-in theme name `TokyoNight` is verified in Task 5.)

- [ ] **Step 3: Write the parser + palette loader**

`theme/.config/theme/lib/generate.sh`:
```bash
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
```

- [ ] **Step 4: Write the failing parser test**

`theme/.config/theme/lib/test.sh`:
```bash
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

exit $fail
```

- [ ] **Step 5: Run the test (expect pass — parser already implemented)**

Run: `bash theme/.config/theme/lib/test.sh`
Expected: four `ok -` lines, exit 0. If any `FAIL`, fix `manifest_get` before continuing.

- [ ] **Step 6: Commit**

```bash
git add theme/
git commit -m "feat(theme): add theme package skeleton, manifests, and parser"
```

---

### Task 2: SketchyBar fragment generator

**Files:**
- Modify: `theme/.config/theme/lib/generate.sh` (add `gen_sketchybar`)
- Modify: `theme/.config/theme/lib/test.sh` (golden comparison)
- Create: `theme/.config/theme/lib/golden/gruvbox-material/sketchybar.sh`
- Create: `theme/.config/theme/lib/golden/tokyo-night/sketchybar.sh`

**Interfaces:**
- Consumes: `load_palette` globals (Task 1).
- Produces: `gen_sketchybar` → writes a zsh file defining all color vars the sketchybar config references (`BAR_COLOR BAR_BORDER_COLOR BG_PRIMARY BG_SECONDARY BG_OVERLAY BG_TRANSPARENT FG FG_MUTED FG_DIM RED ORANGE YELLOW GREEN AQUA BLUE PURPLE ACCENT SPACE_ACTIVE SPACE_INACTIVE BATTERY_OK BATTERY_LOW CPU_BG CALENDAR WIFI CLOCK_FG WEATHER_FG VOLUME_FG POMODORO_FG`) in `0xAARRGGBB` form.

- [ ] **Step 1: Write the golden files (these are the assertions)**

`theme/.config/theme/lib/golden/gruvbox-material/sketchybar.sh`:
```sh
#!/usr/bin/env zsh
# generated by theme-set — do not edit
export BAR_COLOR=0xff282828
export BAR_BORDER_COLOR=0xff504945
export BG_PRIMARY=0xff32302f
export BG_SECONDARY=0xff3a3735
export BG_OVERLAY=0xff504945
export BG_TRANSPARENT=0x00000000
export FG=0xffd4be98
export FG_MUTED=0xffa89984
export FG_DIM=0x66a89984
export RED=0xffea6962
export ORANGE=0xffe78a4e
export YELLOW=0xffd8a657
export GREEN=0xffa9b665
export AQUA=0xff89b482
export BLUE=0xff7daea3
export PURPLE=0xffd3869b
export ACCENT=0xffe78a4e
export SPACE_ACTIVE=0xffd8a657
export SPACE_INACTIVE=0xffa89984
export BATTERY_OK=0xffa9b665
export BATTERY_LOW=0xffea6962
export CPU_BG=0xffe78a4e
export CALENDAR=0xffd8a657
export WIFI=0xff89b482
export CLOCK_FG=0xffd8a657
export WEATHER_FG=0xff89b482
export VOLUME_FG=0xff7daea3
export POMODORO_FG=0xffd4be98
```

`theme/.config/theme/lib/golden/tokyo-night/sketchybar.sh`:
```sh
#!/usr/bin/env zsh
# generated by theme-set — do not edit
export BAR_COLOR=0xff1a1b26
export BAR_BORDER_COLOR=0xff414868
export BG_PRIMARY=0xff16161e
export BG_SECONDARY=0xff24283b
export BG_OVERLAY=0xff414868
export BG_TRANSPARENT=0x00000000
export FG=0xffc0caf5
export FG_MUTED=0xff565f89
export FG_DIM=0x66565f89
export RED=0xfff7768e
export ORANGE=0xffff9e64
export YELLOW=0xffe0af68
export GREEN=0xff9ece6a
export AQUA=0xff7dcfff
export BLUE=0xff7aa2f7
export PURPLE=0xffbb9af7
export ACCENT=0xff7aa2f7
export SPACE_ACTIVE=0xffe0af68
export SPACE_INACTIVE=0xff565f89
export BATTERY_OK=0xff9ece6a
export BATTERY_LOW=0xfff7768e
export CPU_BG=0xffff9e64
export CALENDAR=0xffe0af68
export WIFI=0xff7dcfff
export CLOCK_FG=0xffe0af68
export WEATHER_FG=0xff7dcfff
export VOLUME_FG=0xff7aa2f7
export POMODORO_FG=0xffc0caf5
```

- [ ] **Step 2: Add the golden comparison to the test (failing — no `gen_sketchybar` yet)**

Append to `theme/.config/theme/lib/test.sh` before `exit $fail`:
```bash
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
```

Run: `bash theme/.config/theme/lib/test.sh`
Expected: FAIL — `gen_sketchybar: command not found` / failing lines.

- [ ] **Step 3: Implement `gen_sketchybar`**

Append to `theme/.config/theme/lib/generate.sh`:
```bash
gen_sketchybar() {
  cat <<EOF
#!/usr/bin/env zsh
# generated by theme-set — do not edit
export BAR_COLOR=0xff${bg}
export BAR_BORDER_COLOR=0xff${bg_overlay}
export BG_PRIMARY=0xff${bg_alt}
export BG_SECONDARY=0xff${bg_secondary}
export BG_OVERLAY=0xff${bg_overlay}
export BG_TRANSPARENT=0x00000000
export FG=0xff${fg}
export FG_MUTED=0xff${fg_muted}
export FG_DIM=0x66${fg_muted}
export RED=0xff${red}
export ORANGE=0xff${orange}
export YELLOW=0xff${yellow}
export GREEN=0xff${green}
export AQUA=0xff${aqua}
export BLUE=0xff${blue}
export PURPLE=0xff${purple}
export ACCENT=0xff${accent}
export SPACE_ACTIVE=0xff${yellow}
export SPACE_INACTIVE=0xff${fg_muted}
export BATTERY_OK=0xff${green}
export BATTERY_LOW=0xff${red}
export CPU_BG=0xff${orange}
export CALENDAR=0xff${yellow}
export WIFI=0xff${aqua}
export CLOCK_FG=0xff${yellow}
export WEATHER_FG=0xff${aqua}
export VOLUME_FG=0xff${blue}
export POMODORO_FG=0xff${fg}
EOF
}
```

- [ ] **Step 4: Run the test (expect pass)**

Run: `bash theme/.config/theme/lib/test.sh`
Expected: all `ok -` lines including `ok - sketchybar.sh gruvbox-material` and `ok - sketchybar.sh tokyo-night`, exit 0.

- [ ] **Step 5: Commit**

```bash
git add theme/
git commit -m "feat(theme): generate sketchybar color fragment from manifest"
```

---

### Task 3: theme-set / theme-list scripts + SketchyBar wiring (tracer bullet)

This is the end-to-end tracer: apply a theme, sketchybar re-themes, switch back and forth, git stays clean.

**Files:**
- Create: `theme/.local/bin/theme-set`
- Create: `theme/.local/bin/theme-list`
- Modify: `sketchybar/.config/sketchybar/sketchybarrc:6` (the `source` line)

**Interfaces:**
- Consumes: `generate.sh` (`load_palette`, `gen_sketchybar`).
- Produces: `theme-set <name>` applies a theme; `theme-set --init` applies current-or-default; `theme-list` prints themes marking current. State dir: `${XDG_STATE_HOME:-$HOME/.local/state}/theme/`.

- [ ] **Step 1: Write `theme-set`**

`theme/.local/bin/theme-set`:
```bash
#!/usr/bin/env bash
set -euo pipefail

DOTFILES="$HOME/.dotfiles"
THEMES_DIR="$HOME/.config/theme/themes"
LIB="$HOME/.config/theme/lib"
STATE_DIR="${XDG_STATE_HOME:-$HOME/.local/state}/theme"
DEFAULT_THEME="gruvbox-material"

# shellcheck source=/dev/null
source "$LIB/generate.sh"

list_themes() { for f in "$THEMES_DIR"/*.toml; do basename "$f" .toml; done | sort; }
current_theme() { cat "$STATE_DIR/current" 2>/dev/null || true; }

reload_apps() {
  command -v sketchybar >/dev/null 2>&1 && sketchybar --reload >/dev/null 2>&1 || true
}

apply_theme() {
  local name=$1
  local manifest="$THEMES_DIR/$name.toml"
  [ -f "$manifest" ] || { echo "Unknown theme: $name" >&2; echo "Available: $(list_themes | tr '\n' ' ')" >&2; exit 1; }
  mkdir -p "$STATE_DIR"
  load_palette "$manifest"
  gen_sketchybar > "$STATE_DIR/sketchybar.sh"
  echo "$name" > "$STATE_DIR/current"
  reload_apps
  echo "Applied theme: $name"
}

cycle_theme() {
  local cur; cur="$(current_theme)"
  local -a themes; mapfile -t themes < <(list_themes)
  local next=0 idx
  for idx in "${!themes[@]}"; do
    [ "${themes[$idx]}" = "$cur" ] && next=$(( (idx + 1) % ${#themes[@]} ))
  done
  apply_theme "${themes[$next]}"
}

case "${1:-}" in
  --cycle) cycle_theme ;;
  --init)  apply_theme "$(current_theme || true)" 2>/dev/null || apply_theme "$DEFAULT_THEME" ;;
  "")      echo "usage: theme-set <name>|--cycle|--init" >&2; exit 2 ;;
  *)       apply_theme "$1" ;;
esac
```

(`--init` note: if `current` is empty/invalid, fall back to default. The `apply_theme "$(current_theme)"` with empty arg hits the "Unknown theme" path and exits non-zero, triggering the `|| apply_theme "$DEFAULT_THEME"`.)

- [ ] **Step 2: Write `theme-list`**

`theme/.local/bin/theme-list`:
```bash
#!/usr/bin/env bash
set -euo pipefail
THEMES_DIR="$HOME/.config/theme/themes"
STATE_DIR="${XDG_STATE_HOME:-$HOME/.local/state}/theme"
cur="$(cat "$STATE_DIR/current" 2>/dev/null || true)"
for f in "$THEMES_DIR"/*.toml; do
  name="$(basename "$f" .toml)"
  if [ "$name" = "$cur" ]; then echo "* $name"; else echo "  $name"; fi
done
```

- [ ] **Step 3: Make scripts executable**

Run: `chmod +x theme/.local/bin/theme-set theme/.local/bin/theme-list`

- [ ] **Step 4: Wire sketchybarrc to source the state fragment with fallback**

In `sketchybar/.config/sketchybar/sketchybarrc`, replace line 6:
```sh
source "$HOME/.config/sketchybar/colors.sh"
```
with:
```sh
# Theme colors: prefer generated state fragment, fall back to committed default
_theme_colors="${XDG_STATE_HOME:-$HOME/.local/state}/theme/sketchybar.sh"
if [ -f "$_theme_colors" ]; then source "$_theme_colors"; else source "$HOME/.config/sketchybar/colors.sh"; fi
```

(`colors.sh` stays in the repo as the bootstrap default so a fresh machine renders before `theme-set` runs.)

- [ ] **Step 5: Stow the theme package and apply (manual end-to-end check)**

Run:
```bash
stow -t ~ theme
fish -c 'fish_add_path -g $HOME/.local/bin' 2>/dev/null || true
~/.local/bin/theme-set gruvbox-material
git -C ~/.dotfiles status --porcelain
```
Expected: `Applied theme: gruvbox-material`, the file `~/.local/state/theme/sketchybar.sh` exists, and `git status --porcelain` shows **no** changes to tracked files from applying the theme (only your in-progress task edits). SketchyBar reloads with identical colors.

- [ ] **Step 6: Verify switching is real and reversible**

Run:
```bash
~/.local/bin/theme-set tokyo-night && sleep 1
~/.local/bin/theme-list
~/.local/bin/theme-set gruvbox-material
git -C ~/.dotfiles status --porcelain
```
Expected: bar turns blue-ish (Tokyo Night) then back to Gruvbox; `theme-list` marks the current with `*`; git still clean.

- [ ] **Step 7: Commit**

```bash
git add theme/ sketchybar/.config/sketchybar/sketchybarrc
git commit -m "feat(theme): add theme-set/theme-list and wire sketchybar (tracer bullet)"
```

---

### Task 4: Borders fragment generator + wiring

**Files:**
- Modify: `theme/.config/theme/lib/generate.sh` (add `gen_borders`)
- Modify: `theme/.config/theme/lib/test.sh`
- Create: `theme/.config/theme/lib/golden/gruvbox-material/borders.env`
- Create: `theme/.config/theme/lib/golden/tokyo-night/borders.env`
- Modify: `borders/.config/borders/bordersrc`
- Modify: `theme/.local/bin/theme-set` (write borders.env + reload borders)

**Interfaces:**
- Produces: `gen_borders` → `ACTIVE_COLOR=0xff<accent>` and `INACTIVE_COLOR=0xff<bg_overlay>`.

- [ ] **Step 1: Golden files**

`theme/.config/theme/lib/golden/gruvbox-material/borders.env`:
```sh
ACTIVE_COLOR=0xffe78a4e
INACTIVE_COLOR=0xff504945
```
`theme/.config/theme/lib/golden/tokyo-night/borders.env`:
```sh
ACTIVE_COLOR=0xff7aa2f7
INACTIVE_COLOR=0xff414868
```

- [ ] **Step 2: Add failing golden checks**

Append before `exit $fail` in `test.sh`:
```bash
gen_check gruvbox-material borders.env gen_borders
gen_check tokyo-night     borders.env gen_borders
```
Run: `bash theme/.config/theme/lib/test.sh` → Expected: FAIL (`gen_borders` undefined).

- [ ] **Step 3: Implement `gen_borders`**

Append to `generate.sh`:
```bash
gen_borders() {
  cat <<EOF
ACTIVE_COLOR=0xff${accent}
INACTIVE_COLOR=0xff${bg_overlay}
EOF
}
```
Run: `bash theme/.config/theme/lib/test.sh` → Expected: PASS.

- [ ] **Step 4: Rewrite `bordersrc` to read the state env with fallback**

Replace `borders/.config/borders/bordersrc` entirely with:
```bash
#!/usr/bin/env bash
# JankyBorders — colors come from the theme state fragment, with a fallback.
# Docs: https://github.com/FelixKratz/JankyBorders

ACTIVE_COLOR=0xffe78a4e
INACTIVE_COLOR=0xff504945
_state="${XDG_STATE_HOME:-$HOME/.local/state}/theme/borders.env"
[ -f "$_state" ] && source "$_state"

borders \
  style=round \
  width=3.0 \
  hidpi=on \
  active_color="$ACTIVE_COLOR" \
  inactive_color="$INACTIVE_COLOR" \
  background_color=0x00000000 &
```

- [ ] **Step 5: Make theme-set write borders.env and reload borders**

In `theme-set`, inside `apply_theme`, after the `gen_sketchybar` line add:
```bash
  gen_borders > "$STATE_DIR/borders.env"
```
In `reload_apps`, add:
```bash
  if command -v borders >/dev/null 2>&1; then
    pkill -x borders >/dev/null 2>&1 || true
    bash "$HOME/.config/borders/bordersrc" >/dev/null 2>&1 || true
  fi
```

- [ ] **Step 6: Verify**

Run:
```bash
stow -R -t ~ theme borders
~/.local/bin/theme-set tokyo-night && sleep 1   # borders turn blue
~/.local/bin/theme-set gruvbox-material          # borders back to orange
git -C ~/.dotfiles status --porcelain
```
Expected: active window border color changes with the theme; git clean.

- [ ] **Step 7: Commit**

```bash
git add theme/ borders/.config/borders/bordersrc
git commit -m "feat(theme): theme JankyBorders from manifest"
```

---

### Task 5: Ghostty fragment generator + config-file wiring

**Files:**
- Modify: `theme/.config/theme/lib/generate.sh` (add `gen_ghostty`)
- Modify: `theme/.config/theme/lib/test.sh`
- Create: `theme/.config/theme/lib/golden/gruvbox-material/ghostty.conf`
- Create: `theme/.config/theme/lib/golden/tokyo-night/ghostty.conf`
- Modify: `ghostty/.config/ghostty/config`
- Modify: `theme/.local/bin/theme-set` (write ghostty.conf)

**Interfaces:**
- Consumes: `manifest_get` (native section).
- Produces: `gen_ghostty MANIFEST` → a single line `theme = <native.ghostty>`.

- [ ] **Step 1: Verify Ghostty's Tokyo Night built-in theme name**

Run: `ghostty +list-themes 2>/dev/null | grep -i tokyo`
Expected: confirms the exact name. If it is `TokyoNight Night` (or similar) rather than `TokyoNight`, update `[native].ghostty` in `tokyo-night.toml` and the golden file below to match the verified name.

- [ ] **Step 2: Golden files** (using the verified names)

`theme/.config/theme/lib/golden/gruvbox-material/ghostty.conf`:
```
theme = Gruvbox Material Dark
```
`theme/.config/theme/lib/golden/tokyo-night/ghostty.conf`:
```
theme = TokyoNight
```

- [ ] **Step 3: Add failing golden checks** (note: `gen_ghostty` takes the manifest path as its arg)

Append before `exit $fail` in `test.sh`:
```bash
gen_check gruvbox-material ghostty.conf gen_ghostty "$THEMES/gruvbox-material.toml"
gen_check tokyo-night     ghostty.conf gen_ghostty "$THEMES/tokyo-night.toml"
```
Run: `bash theme/.config/theme/lib/test.sh` → Expected: FAIL (`gen_ghostty` undefined).

- [ ] **Step 4: Implement `gen_ghostty`**

Append to `generate.sh`:
```bash
gen_ghostty() {
  local m=$1
  echo "theme = $(manifest_get "$m" native ghostty)"
}
```
Run: `bash theme/.config/theme/lib/test.sh` → Expected: PASS.

- [ ] **Step 5: Wire ghostty config to include the state fragment**

In `ghostty/.config/ghostty/config`, replace the line:
```
theme = Gruvbox Material Dark
```
with (the `?` prefix makes the include optional — Ghostty ignores it if the file is missing):
```
config-file = ?~/.local/state/theme/ghostty.conf
```

- [ ] **Step 6: Make theme-set write ghostty.conf**

In `apply_theme`, after the `gen_borders` line add:
```bash
  gen_ghostty "$manifest" > "$STATE_DIR/ghostty.conf"
```

- [ ] **Step 7: Verify**

Run:
```bash
stow -R -t ~ theme ghostty
~/.local/bin/theme-set tokyo-night
cat ~/.local/state/theme/ghostty.conf
git -C ~/.dotfiles status --porcelain
```
Expected: file contains `theme = TokyoNight`; git clean. Open a **new** Ghostty window → it uses Tokyo Night colors (existing windows keep their theme until reloaded — documented trade-off). Switch back with `theme-set gruvbox-material`.

- [ ] **Step 8: Commit**

```bash
git add theme/ ghostty/.config/ghostty/config
git commit -m "feat(theme): theme Ghostty via generated config-file include"
```

---

### Task 6: lazygit fragment generator + LG_CONFIG_FILE wiring

**Files:**
- Modify: `theme/.config/theme/lib/generate.sh` (add `gen_lazygit`)
- Modify: `theme/.config/theme/lib/test.sh`
- Create: `theme/.config/theme/lib/golden/gruvbox-material/lazygit.yml`
- Create: `theme/.config/theme/lib/golden/tokyo-night/lazygit.yml`
- Modify: `lazygit/.config/lazygit/config.yml` (remove the `theme:` block)
- Modify: `fish/.config/fish/config.fish` (set `LG_CONFIG_FILE`)
- Modify: `theme/.local/bin/theme-set` (write lazygit.yml)

**Interfaces:**
- Produces: `gen_lazygit` → a YAML doc containing only `gui.theme` + `gui.authorColors` + `gui.nerdFontsVersion`, merged by lazygit on top of the base config.

- [ ] **Step 1: Golden files**

`theme/.config/theme/lib/golden/gruvbox-material/lazygit.yml`:
```yaml
gui:
  theme:
    activeBorderColor:
      - "#e78a4e"
      - bold
    inactiveBorderColor:
      - "#504945"
    searchingActiveBorderColor:
      - "#d8a657"
      - bold
    optionsTextColor:
      - "#7daea3"
    selectedLineBgColor:
      - "#665c54"
    cherryPickedCommitBgColor:
      - "#504945"
    cherryPickedCommitFgColor:
      - "#d8a657"
    markedBaseCommitBgColor:
      - "#504945"
    markedBaseCommitFgColor:
      - "#ea6962"
    unstagedChangesColor:
      - "#ea6962"
    defaultFgColor:
      - "#d4be98"
  authorColors:
    "*": "#d3869b"
  nerdFontsVersion: "3"
```
`theme/.config/theme/lib/golden/tokyo-night/lazygit.yml`:
```yaml
gui:
  theme:
    activeBorderColor:
      - "#7aa2f7"
      - bold
    inactiveBorderColor:
      - "#414868"
    searchingActiveBorderColor:
      - "#e0af68"
      - bold
    optionsTextColor:
      - "#7aa2f7"
    selectedLineBgColor:
      - "#33467c"
    cherryPickedCommitBgColor:
      - "#414868"
    cherryPickedCommitFgColor:
      - "#e0af68"
    markedBaseCommitBgColor:
      - "#414868"
    markedBaseCommitFgColor:
      - "#f7768e"
    unstagedChangesColor:
      - "#f7768e"
    defaultFgColor:
      - "#c0caf5"
  authorColors:
    "*": "#bb9af7"
  nerdFontsVersion: "3"
```

- [ ] **Step 2: Add failing golden checks**

Append before `exit $fail` in `test.sh`:
```bash
gen_check gruvbox-material lazygit.yml gen_lazygit
gen_check tokyo-night     lazygit.yml gen_lazygit
```
Run: `bash theme/.config/theme/lib/test.sh` → Expected: FAIL.

- [ ] **Step 3: Implement `gen_lazygit`**

Append to `generate.sh`:
```bash
gen_lazygit() {
  cat <<EOF
gui:
  theme:
    activeBorderColor:
      - "#${accent}"
      - bold
    inactiveBorderColor:
      - "#${bg_overlay}"
    searchingActiveBorderColor:
      - "#${yellow}"
      - bold
    optionsTextColor:
      - "#${blue}"
    selectedLineBgColor:
      - "#${bg_selection}"
    cherryPickedCommitBgColor:
      - "#${bg_overlay}"
    cherryPickedCommitFgColor:
      - "#${yellow}"
    markedBaseCommitBgColor:
      - "#${bg_overlay}"
    markedBaseCommitFgColor:
      - "#${red}"
    unstagedChangesColor:
      - "#${red}"
    defaultFgColor:
      - "#${fg}"
  authorColors:
    "*": "#${purple}"
  nerdFontsVersion: "3"
EOF
}
```

Note: for gruvbox `optionsTextColor` the original was `#7daea3` (= `blue` role), and `searchingActiveBorderColor` was `#d8a657` (= `yellow`) — the generator matches the original Gruvbox values exactly. Run: `bash theme/.config/theme/lib/test.sh` → Expected: PASS.

- [ ] **Step 4: Strip the theme block from the base lazygit config**

Edit `lazygit/.config/lazygit/config.yml`: delete the entire `gui.theme`, `gui.authorColors`, and `gui.nerdFontsVersion` block (lines shown in the design — everything under `gui:` that is theme-related). Keep any non-theme keys. If `gui:` becomes empty, remove the `gui:` key too. The theme now comes from the merged state file.

- [ ] **Step 5: Set `LG_CONFIG_FILE` in fish**

In `fish/.config/fish/config.fish`, add (top-level, near other `set -gx`):
```fish
set -gx LG_CONFIG_FILE "$HOME/.config/lazygit/config.yml,$HOME/.local/state/theme/lazygit.yml"
```

- [ ] **Step 6: Make theme-set write lazygit.yml**

In `apply_theme`, after the `gen_ghostty` line add:
```bash
  gen_lazygit > "$STATE_DIR/lazygit.yml"
```

- [ ] **Step 7: Verify the merge works**

Run:
```bash
stow -R -t ~ theme lazygit fish
~/.local/bin/theme-set gruvbox-material
LG_CONFIG_FILE="$HOME/.config/lazygit/config.yml,$HOME/.local/state/theme/lazygit.yml" lazygit --print-config | grep -A2 activeBorderColor
```
Expected: printed config shows `#e78a4e` for the active border, proving the merge. (If `--print-config` ignores `LG_CONFIG_FILE`, instead open `lazygit` in a fresh fish session and confirm the orange borders visually.) Switch to `tokyo-night` and confirm blue. `git status` clean.

- [ ] **Step 8: Commit**

```bash
git add theme/ lazygit/.config/lazygit/config.yml fish/.config/fish/config.fish
git commit -m "feat(theme): theme lazygit via LG_CONFIG_FILE merge"
```

---

### Task 7: Neovim active-theme read

**Files:**
- Modify: `theme/.config/theme/lib/generate.sh` (add `gen_nvim`)
- Modify: `theme/.config/theme/lib/test.sh`
- Create: `theme/.config/theme/lib/golden/gruvbox-material/nvim`
- Create: `theme/.config/theme/lib/golden/tokyo-night/nvim`
- Modify: `nvim/.config/nvim/lua/plugins/colorscheme.lua`
- Modify: `theme/.local/bin/theme-set` (write nvim name)

**Interfaces:**
- Produces: `gen_nvim MANIFEST` → the bare nvim colorscheme name (`native.nvim`). theme-set writes it to `state/nvim`.

- [ ] **Step 1: Golden files**

`theme/.config/theme/lib/golden/gruvbox-material/nvim`:
```
gruvbox-material
```
`theme/.config/theme/lib/golden/tokyo-night/nvim`:
```
tokyonight
```

- [ ] **Step 2: Add failing golden checks**

Append before `exit $fail` in `test.sh`:
```bash
gen_check gruvbox-material nvim gen_nvim "$THEMES/gruvbox-material.toml"
gen_check tokyo-night     nvim gen_nvim "$THEMES/tokyo-night.toml"
```
Run: `bash theme/.config/theme/lib/test.sh` → Expected: FAIL.

- [ ] **Step 3: Implement `gen_nvim`**

Append to `generate.sh`:
```bash
gen_nvim() {
  local m=$1
  manifest_get "$m" native nvim
}
```
Run: `bash theme/.config/theme/lib/test.sh` → Expected: PASS.

- [ ] **Step 4: Make colorscheme.lua read the active theme with a fallback**

Replace `nvim/.config/nvim/lua/plugins/colorscheme.lua` entirely with:
```lua
-- Active colorscheme is driven by the theme-set state file, with a safe fallback.
local function active_colorscheme()
  local path = vim.fn.expand("~/.local/state/theme/nvim")
  local f = io.open(path, "r")
  if f then
    local name = f:read("l")
    f:close()
    if name and #name > 0 then
      return name
    end
  end
  return "gruvbox-material"
end

local scheme = active_colorscheme()

return {
  {
    "sainnhe/gruvbox-material",
    lazy = false,
    priority = 1000,
    config = function()
      vim.opt.background = "dark"
      vim.opt.termguicolors = true
      vim.g.gruvbox_material_background = "medium"
      vim.g.gruvbox_material_foreground = "material"
      vim.g.gruvbox_material_better_performance = 1
      vim.g.gruvbox_material_enable_italic = 1
    end,
  },
  { "folke/tokyonight.nvim", lazy = true },
  {
    "LazyVim/LazyVim",
    opts = {
      colorscheme = scheme,
    },
  },
}
```

(The hardcoded `vim.cmd.colorscheme(...)` is removed; LazyVim applies `opts.colorscheme`. The gruvbox `g:` options are harmless when tokyonight is active. tokyonight.nvim is already in `lazy-lock.json`; the explicit spec guarantees it is installed.)

- [ ] **Step 5: Make theme-set write the nvim name**

In `apply_theme`, after the `gen_lazygit` line add:
```bash
  gen_nvim "$manifest" > "$STATE_DIR/nvim"
```

- [ ] **Step 6: Verify**

Run:
```bash
stow -R -t ~ theme nvim
~/.local/bin/theme-set tokyo-night
cat ~/.local/state/theme/nvim   # -> tokyonight
nvim -c 'echo g:colors_name' -c 'qa' 2>/dev/null || nvim   # opens with Tokyo Night
~/.local/bin/theme-set gruvbox-material
```
Expected: a freshly launched nvim uses the active theme (Tokyo Night, then Gruvbox after switching). git clean.

- [ ] **Step 7: Commit**

```bash
git add theme/ nvim/.config/nvim/lua/plugins/colorscheme.lua
git commit -m "feat(theme): drive nvim colorscheme from theme state"
```

---

### Task 8: btop package + theme generator + wiring

**Files:**
- Create: `btop/.config/btop/btop.conf`
- Modify: `theme/.config/theme/lib/generate.sh` (add `gen_btop`)
- Modify: `theme/.config/theme/lib/test.sh`
- Create: `theme/.config/theme/lib/golden/gruvbox-material/btop.theme`
- Create: `theme/.config/theme/lib/golden/tokyo-night/btop.theme`
- Modify: `theme/.local/bin/theme-set` (write btop theme + ensure dir)

**Interfaces:**
- Produces: `gen_btop` → a btop `.theme` file (`theme[key]="#hex"` lines). theme-set writes it to `~/.config/btop/themes/current.theme`; `btop.conf` sets `color_theme = "current"`.

- [ ] **Step 1: Create btop.conf pointing at the `current` theme**

`btop/.config/btop/btop.conf`:
```conf
color_theme = "current"
theme_background = False
truecolor = True
vim_keys = True
rounded_corners = True
update_ms = 1000
```

- [ ] **Step 2: Golden files**

`theme/.config/theme/lib/golden/gruvbox-material/btop.theme`:
```theme
# Gruvbox Material — generated by theme-set
theme[main_bg]=""
theme[main_fg]="#d4be98"
theme[title]="#d4be98"
theme[hi_fg]="#e78a4e"
theme[selected_bg]="#504945"
theme[selected_fg]="#e78a4e"
theme[inactive_fg]="#a89984"
theme[graph_text]="#a89984"
theme[meter_bg]="#504945"
theme[proc_misc]="#89b482"
theme[cpu_box]="#7daea3"
theme[mem_box]="#a9b665"
theme[net_box]="#d3869b"
theme[proc_box]="#e78a4e"
theme[div_line]="#504945"
theme[temp_start]="#a9b665"
theme[temp_mid]="#d8a657"
theme[temp_end]="#ea6962"
theme[cpu_start]="#a9b665"
theme[cpu_mid]="#d8a657"
theme[cpu_end]="#ea6962"
theme[free_start]="#89b482"
theme[free_mid]="#7daea3"
theme[free_end]="#d3869b"
theme[cached_start]="#7daea3"
theme[cached_mid]="#d3869b"
theme[cached_end]="#ea6962"
theme[available_start]="#d8a657"
theme[available_mid]="#e78a4e"
theme[available_end]="#ea6962"
theme[used_start]="#a9b665"
theme[used_mid]="#d8a657"
theme[used_end]="#ea6962"
theme[download_start]="#89b482"
theme[download_mid]="#7daea3"
theme[download_end]="#d3869b"
theme[upload_start]="#d8a657"
theme[upload_mid]="#e78a4e"
theme[upload_end]="#ea6962"
theme[process_start]="#a9b665"
theme[process_mid]="#d8a657"
theme[process_end]="#ea6962"
```
`theme/.config/theme/lib/golden/tokyo-night/btop.theme`:
```theme
# Tokyo Night — generated by theme-set
theme[main_bg]=""
theme[main_fg]="#c0caf5"
theme[title]="#c0caf5"
theme[hi_fg]="#7aa2f7"
theme[selected_bg]="#414868"
theme[selected_fg]="#7aa2f7"
theme[inactive_fg]="#565f89"
theme[graph_text]="#565f89"
theme[meter_bg]="#414868"
theme[proc_misc]="#7dcfff"
theme[cpu_box]="#7aa2f7"
theme[mem_box]="#9ece6a"
theme[net_box]="#bb9af7"
theme[proc_box]="#ff9e64"
theme[div_line]="#414868"
theme[temp_start]="#9ece6a"
theme[temp_mid]="#e0af68"
theme[temp_end]="#f7768e"
theme[cpu_start]="#9ece6a"
theme[cpu_mid]="#e0af68"
theme[cpu_end]="#f7768e"
theme[free_start]="#7dcfff"
theme[free_mid]="#7aa2f7"
theme[free_end]="#bb9af7"
theme[cached_start]="#7aa2f7"
theme[cached_mid]="#bb9af7"
theme[cached_end]="#f7768e"
theme[available_start]="#e0af68"
theme[available_mid]="#ff9e64"
theme[available_end]="#f7768e"
theme[used_start]="#9ece6a"
theme[used_mid]="#e0af68"
theme[used_end]="#f7768e"
theme[download_start]="#7dcfff"
theme[download_mid]="#7aa2f7"
theme[download_end]="#bb9af7"
theme[upload_start]="#e0af68"
theme[upload_mid]="#ff9e64"
theme[upload_end]="#f7768e"
theme[process_start]="#9ece6a"
theme[process_mid]="#e0af68"
theme[process_end]="#f7768e"
```

- [ ] **Step 3: Add failing golden checks**

Append before `exit $fail` in `test.sh`:
```bash
gen_check gruvbox-material btop.theme gen_btop
gen_check tokyo-night     btop.theme gen_btop
```
Run: `bash theme/.config/theme/lib/test.sh` → Expected: FAIL.

- [ ] **Step 4: Implement `gen_btop`**

Append to `generate.sh`. Note the first comment line must match the golden header per theme — derive a display name from `$accent`/manifest is fragile, so accept a small arg. Use the manifest name via a global `THEME_DISPLAY` set by theme-set; for the test, set it before calling. Simpler: hardcode the comment from the palette is not possible, so pass display name as `$1`:
```bash
gen_btop() {
  local title=${1:-Theme}
  cat <<EOF
# ${title} — generated by theme-set
theme[main_bg]=""
theme[main_fg]="#${fg}"
theme[title]="#${fg}"
theme[hi_fg]="#${accent}"
theme[selected_bg]="#${bg_overlay}"
theme[selected_fg]="#${accent}"
theme[inactive_fg]="#${fg_muted}"
theme[graph_text]="#${fg_muted}"
theme[meter_bg]="#${bg_overlay}"
theme[proc_misc]="#${aqua}"
theme[cpu_box]="#${blue}"
theme[mem_box]="#${green}"
theme[net_box]="#${purple}"
theme[proc_box]="#${orange}"
theme[div_line]="#${bg_overlay}"
theme[temp_start]="#${green}"
theme[temp_mid]="#${yellow}"
theme[temp_end]="#${red}"
theme[cpu_start]="#${green}"
theme[cpu_mid]="#${yellow}"
theme[cpu_end]="#${red}"
theme[free_start]="#${aqua}"
theme[free_mid]="#${blue}"
theme[free_end]="#${purple}"
theme[cached_start]="#${blue}"
theme[cached_mid]="#${purple}"
theme[cached_end]="#${red}"
theme[available_start]="#${yellow}"
theme[available_mid]="#${orange}"
theme[available_end]="#${red}"
theme[used_start]="#${green}"
theme[used_mid]="#${yellow}"
theme[used_end]="#${red}"
theme[download_start]="#${aqua}"
theme[download_mid]="#${blue}"
theme[download_end]="#${purple}"
theme[upload_start]="#${yellow}"
theme[upload_mid]="#${orange}"
theme[upload_end]="#${red}"
theme[process_start]="#${green}"
theme[process_mid]="#${yellow}"
theme[process_end]="#${red}"
EOF
}
```
Update the two `gen_check ... btop.theme` lines in `test.sh` to pass the display title so the comment matches the golden header:
```bash
gen_check gruvbox-material btop.theme gen_btop "Gruvbox Material"
gen_check tokyo-night     btop.theme gen_btop "Tokyo Night"
```
(`gen_check`'s 4th arg is already forwarded as `$1` to the gen function.) Run: `bash theme/.config/theme/lib/test.sh` → Expected: PASS.

- [ ] **Step 5: Make theme-set write btop's current theme**

In `theme-set`, add a display-name lookup and write the theme. After the `gen_nvim` line in `apply_theme`:
```bash
  local display; display="$(manifest_get "$manifest" theme name)"
  mkdir -p "$HOME/.config/btop/themes"
  gen_btop "$display" > "$HOME/.config/btop/themes/current.theme"
```
(Using the manifest `name` as the comment title is fine — the golden test uses friendlier names but btop ignores the comment; the golden header is only asserted in unit tests where we pass the display string explicitly.)

- [ ] **Step 6: Stow btop with `--no-folding` so `themes/` is a real dir**

Run:
```bash
stow --no-folding -t ~ btop
stow -R -t ~ theme
~/.local/bin/theme-set gruvbox-material
ls -la ~/.config/btop/themes/current.theme   # real file, not a repo symlink
git -C ~/.dotfiles status --porcelain         # clean
```
Expected: `current.theme` exists as a normal file in a real directory; git clean.

- [ ] **Step 7: Verify in btop**

Run: `btop` (then `q` to quit). Expected: btop renders in Gruvbox colors. `theme-set tokyo-night`, relaunch btop → Tokyo Night.

- [ ] **Step 8: Commit**

```bash
git add theme/ btop/
git commit -m "feat(theme): add btop package themed from manifest"
```

---

### Task 9: Starship palette switching

**Files:**
- Modify: `starship/.config/starship.toml` (convert hex → palette names, define both palettes)
- Modify: `theme/.config/theme/lib/generate.sh` (add `gen_starship`)
- Modify: `theme/.config/theme/lib/test.sh`
- Modify: `fish/.config/fish/config.fish` (set `STARSHIP_CONFIG`)
- Modify: `theme/.local/bin/theme-set` (write starship state config)

**Interfaces:**
- Produces: `gen_starship BASE_CONFIG THEME_NAME` → the base config with the top-level `palette =` line set to `THEME_NAME`. Written to `state/starship.toml`; fish points `STARSHIP_CONFIG` there.

- [ ] **Step 1: Rewrite starship.toml to use palette color names + define palettes**

Edit `starship/.config/starship.toml`:
1. Add a top-level palette line right after `add_newline = false`:
   ```toml
   palette = "gruvbox-material"
   ```
2. Replace every hardcoded hex with its palette role name (drop the `#`, keep modifiers like `bold`/`dimmed`):
   - `#7daea3` → `blue`
   - `#d8a657` → `yellow`
   - `#ea6962` → `red`
   - `#a9b665` → `green`
   - `#d3869b` → `purple`
   - `#89b482` → `aqua`
   (e.g. `style = "bold #7daea3"` → `style = "bold blue"`; `[directory] style = "bold #7daea3"` likewise; `[docker_context] style = "#7daea3 dimmed"` → `"blue dimmed"`.)
3. Append both palette definitions at the end of the file:
   ```toml
   [palettes.gruvbox-material]
   blue   = "#7daea3"
   yellow = "#d8a657"
   red    = "#ea6962"
   green  = "#a9b665"
   purple = "#d3869b"
   aqua   = "#89b482"

   [palettes.tokyo-night]
   blue   = "#7aa2f7"
   yellow = "#e0af68"
   red    = "#f7768e"
   green  = "#9ece6a"
   purple = "#bb9af7"
   aqua   = "#7dcfff"
   ```

Verify nothing references a color outside this set: `grep -oE '#[0-9a-f]{6}' starship/.config/starship.toml | sort -u` should now only appear inside the `[palettes.*]` blocks.

- [ ] **Step 2: Implement `gen_starship`**

Append to `generate.sh`:
```bash
gen_starship() {
  local base=$1 name=$2
  sed "s/^palette = .*/palette = \"${name}\"/" "$base"
}
```

- [ ] **Step 3: Add a test for the palette switch**

Append before `exit $fail` in `test.sh`:
```bash
# gen_starship: the active palette line is rewritten, palettes preserved
base="$THEMES/../../../../starship/.config/starship.toml"
if [ -f "$base" ]; then
  out="$(gen_starship "$base" tokyo-night)"
  check "starship palette switched" "$(echo "$out" | grep -m1 '^palette =')" 'palette = "tokyo-night"'
  check "starship keeps gruvbox palette def" "$(echo "$out" | grep -c '\[palettes.gruvbox-material\]')" "1"
fi
```
Run: `bash theme/.config/theme/lib/test.sh` → Expected: PASS (the path resolves from the lib dir to the repo's starship package; if running outside the repo it is skipped).

- [ ] **Step 4: Point STARSHIP_CONFIG at the state file in fish**

In `fish/.config/fish/config.fish`, add near the other `set -gx`:
```fish
set -gx STARSHIP_CONFIG "$HOME/.local/state/theme/starship.toml"
```

- [ ] **Step 5: Make theme-set write the starship state config**

In `apply_theme`, after the btop block add:
```bash
  if [ -f "$HOME/.config/starship.toml" ]; then
    gen_starship "$HOME/.config/starship.toml" "$name" > "$STATE_DIR/starship.toml"
  fi
```

- [ ] **Step 6: Verify**

Run:
```bash
stow -R -t ~ theme starship fish
~/.local/bin/theme-set tokyo-night
grep -m1 '^palette' ~/.local/state/theme/starship.toml   # palette = "tokyo-night"
STARSHIP_CONFIG="$HOME/.local/state/theme/starship.toml" starship prompt 2>/dev/null | head -1 || true
~/.local/bin/theme-set gruvbox-material
git -C ~/.dotfiles status --porcelain
```
Expected: state config selects `tokyo-night`; a new fish prompt reflects the palette; git clean.

- [ ] **Step 7: Commit**

```bash
git add theme/ starship/.config/starship.toml fish/.config/fish/config.fish
git commit -m "feat(theme): switch starship palette per theme"
```

---

### Task 10: Wallpaper, theme cycling, and AeroSpace keybind

**Files:**
- Modify: `theme/.local/bin/theme-set` (add `set_wallpaper`, call it)
- Modify: `aerospace/.aerospace.toml` (add `alt-shift-t`)

**Interfaces:**
- Consumes: `manifest_get` (`[theme].wallpaper`), `cycle_theme` (Task 3).
- Produces: theme-set applies the wallpaper if the manifest names an existing file; `alt-shift-t` cycles themes.

- [ ] **Step 1: Add `set_wallpaper` to theme-set**

In `theme-set`, add the function (above `apply_theme`):
```bash
set_wallpaper() {
  local manifest=$1 wp path
  wp="$(manifest_get "$manifest" theme wallpaper)"
  [ -n "$wp" ] || return 0
  path="$DOTFILES/wallpapers/$wp"
  if [ ! -f "$path" ]; then
    echo "wallpaper not found: $path (skipping)" >&2
    return 0
  fi
  osascript -e "tell application \"System Events\" to tell every desktop to set picture to \"$path\"" >/dev/null 2>&1 || true
}
```
And call it in `apply_theme`, right before `reload_apps`:
```bash
  set_wallpaper "$manifest"
```

- [ ] **Step 2: Verify wallpaper applies for gruvbox and is skipped (not errored) for tokyo-night**

Run:
```bash
stow -R -t ~ theme
~/.local/bin/theme-set gruvbox-material   # desktop wallpaper changes to gruvbox_astro.jpg
~/.local/bin/theme-set tokyo-night        # prints "wallpaper not found ... (skipping)", no crash
```
Expected: Gruvbox sets the wallpaper; Tokyo Night skips gracefully (empty `wallpaper` → returns early, no message). Exit code 0 both times.

- [ ] **Step 3: Add the cycle keybind to AeroSpace**

In `aerospace/.aerospace.toml`, under `[mode.main.binding]`, after the `alt-shift-c = 'reload-config'` line add:
```toml
# Cycle theme (omarchy-style)
alt-shift-t = 'exec-and-forget /Users/luisfelipej/.local/bin/theme-set --cycle'
```

- [ ] **Step 4: Verify the keybind**

Run: `stow -R -t ~ aerospace && aerospace reload-config`
Then press `alt-shift-t` twice. Expected: the whole environment (bar, borders, wallpaper) cycles Gruvbox → Tokyo Night → Gruvbox. `git -C ~/.dotfiles status --porcelain` stays clean.

- [ ] **Step 5: Commit**

```bash
git add theme/ aerospace/.aerospace.toml
git commit -m "feat(theme): set wallpaper per theme and bind alt-shift-t to cycle"
```

---

### Task 11: Idempotency + full test suite + integration check

**Files:**
- Modify: `theme/.config/theme/lib/test.sh` (idempotency + shell-validity checks)
- Modify: `Makefile` (add `test-theme` target)

**Interfaces:**
- Produces: `make test-theme` runs the whole generator test suite.

- [ ] **Step 1: Add idempotency and validity checks**

Append before `exit $fail` in `test.sh`:
```bash
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
```

- [ ] **Step 2: Add the Makefile target**

In `Makefile`, add `test-theme` to `.PHONY` and define:
```makefile
test-theme:
	@bash theme/.config/theme/lib/test.sh
```

- [ ] **Step 3: Run the full suite**

Run: `make test-theme`
Expected: every line is `ok -`, exit 0. No `FAIL`.

- [ ] **Step 4: Full integration check (clean-git invariant)**

Run:
```bash
before="$(git -C ~/.dotfiles status --porcelain)"
for t in gruvbox-material tokyo-night gruvbox-material tokyo-night; do ~/.local/bin/theme-set "$t" >/dev/null; done
after="$(git -C ~/.dotfiles status --porcelain)"
[ "$before" = "$after" ] && echo "INVARIANT OK: git unchanged by switching" || { echo "INVARIANT BROKEN"; git -C ~/.dotfiles status --porcelain; }
```
Expected: `INVARIANT OK`.

- [ ] **Step 5: Commit**

```bash
git add theme/ Makefile
git commit -m "test(theme): add idempotency, validity, and make test-theme target"
```

---

### Task 12: Font coherence — CaskaydiaMono Nerd Font

**Files:**
- Modify: `Brewfile` (add the cask)
- Modify: `ghostty/.config/ghostty/config:3`
- Modify: `sketchybar/.config/sketchybar/sketchybarrc:3-4`

- [ ] **Step 1: Confirm the cask name and install**

Run: `brew search caskaydia` (or `brew search "font-caskaydia"`)
Expected: shows the cask. Use the verified identifier in the next step (expected `font-caskaydia-mono-nerd-font`). Then:
```bash
brew install --cask font-caskaydia-mono-nerd-font
```

- [ ] **Step 2: Add the cask to the Brewfile**

In `Brewfile`, in the `cask` block (alphabetical-ish, near the other `font-*` casks), add:
```ruby
cask "font-caskaydia-mono-nerd-font"
```

- [ ] **Step 3: Point Ghostty at CaskaydiaMono**

In `ghostty/.config/ghostty/config`, change line 3:
```
font-family = "IosevkaTerm Nerd Font Mono"
```
to:
```
font-family = "CaskaydiaMono Nerd Font"
```

- [ ] **Step 4: Point SketchyBar at CaskaydiaMono**

In `sketchybar/.config/sketchybar/sketchybarrc`, change lines 3-4:
```sh
ICON_FONT="JetBrainsMono Nerd Font"
LABEL_FONT="IosevkaTerm Nerd Font Mono"
```
to:
```sh
ICON_FONT="CaskaydiaMono Nerd Font"
LABEL_FONT="CaskaydiaMono Nerd Font"
```

- [ ] **Step 5: Verify glyph coverage**

Run: `stow -R -t ~ ghostty sketchybar && sketchybar --reload`
Open a new Ghostty window. Expected: text renders in CaskaydiaMono; SketchyBar icons (workspace numbers, app glyphs, weather/clock/battery icons) still render correctly — no tofu boxes. If any icon glyph is missing, note it and (fallback) keep `ICON_FONT="JetBrainsMono Nerd Font"` while leaving `LABEL_FONT` on CaskaydiaMono.

- [ ] **Step 6: Commit**

```bash
git add Brewfile ghostty/.config/ghostty/config sketchybar/.config/sketchybar/sketchybarrc
git commit -m "feat(fonts): standardize on CaskaydiaMono Nerd Font"
```

---

### Task 13: TUIs — btop, lazydocker, dust, procs

**Files:**
- Modify: `Brewfile`
- Modify: `fish/.config/fish/config.fish` (abbreviation)

- [ ] **Step 1: Install the tools**

Run:
```bash
brew install btop lazydocker dust procs
```
Expected: all four install (btop's config was added in Task 8; `dust`/`procs` need no config).

- [ ] **Step 2: Add them to the Brewfile**

In `Brewfile`, in the `brew` block (keep it grouped sensibly), add:
```ruby
brew "btop"
brew "lazydocker"
brew "dust"
brew "procs"
```

- [ ] **Step 3: Add a fish abbreviation for lazydocker**

In `fish/.config/fish/config.fish`, in the same interactive block as the existing `abbr --add` lines, add:
```fish
    abbr --add lzd lazydocker
```

- [ ] **Step 4: Verify**

Run:
```bash
stow -R -t ~ fish
brew bundle check --file=Brewfile --verbose 2>&1 | tail -5
```
Expected: `brew bundle check` reports the dependencies satisfied (or lists only unrelated pre-existing gaps). In a fresh fish session, `lzd` expands to `lazydocker`.

- [ ] **Step 5: Commit**

```bash
git add Brewfile fish/.config/fish/config.fish
git commit -m "feat(tui): add btop, lazydocker, dust, procs"
```

---

### Task 14: Bootstrap, package registration, gitignore, README

**Files:**
- Modify: `install.sh` (add packages + theme-set bootstrap)
- Modify: `Makefile` (add `theme`, `btop` to `PACKAGES`; handle `--no-folding` for btop)
- Modify: `.gitignore`
- Modify: `README.md`

- [ ] **Step 1: Ignore the runtime btop symlink target**

In `.gitignore`, add:
```
btop/.config/btop/themes/current.theme
```
(State fragments live under `~/.local/state`, outside the repo, so nothing else is needed.)

- [ ] **Step 2: Register packages in install.sh and bootstrap the theme**

In `install.sh`, update the `PACKAGES` array (step 5) to include `theme`:
```bash
PACKAGES=(sketchybar nvim fish ghostty tmux claude git starship mise theme)
```
After the stow loop (step 5), add a new step to stow btop without folding and apply the default theme:
```bash
# 5b. btop needs a real themes/ dir for the generated current.theme
echo "Stowing btop (no-folding)..."
stow --no-folding -R -t ~ btop

# 5c. Ensure ~/.local/bin on PATH and apply the default theme
fish -c 'fish_add_path -g $HOME/.local/bin' 2>/dev/null || true
echo "Applying default theme..."
"$HOME/.local/bin/theme-set" --init
```

- [ ] **Step 3: Register packages in the Makefile**

In `Makefile`, add `theme` to `PACKAGES` (btop is stowed with `--no-folding` separately, so keep it out of the generic loop). Add a dedicated target and include it in `stow`/`restow` flows:
```makefile
PACKAGES = sketchybar nvim fish ghostty tmux claude git starship mise lf aerospace borders lazygit theme

stow-btop:
	@echo "Stowing btop (no-folding)..."
	@stow --no-folding -t ~ btop
```
Add `stow-btop` to `.PHONY`. (Document that `make stow` should be followed by `make stow-btop` on first setup; `install.sh` already does both.)

- [ ] **Step 4: Document the theming system in the README**

In `README.md`, add a `theme` and `btop` row to the Packages table and a new section:
```markdown
## Theming

Themes are defined once in `theme/.config/theme/themes/<name>.toml` and applied
across the whole environment (sketchybar, borders, ghostty, lazygit, nvim, btop,
starship, wallpaper) by a generator that writes to `~/.local/state/theme/`.

```bash
theme-set gruvbox-material   # apply a theme
theme-set tokyo-night
theme-list                   # list themes (current marked with *)
theme-set --cycle            # next theme (bound to alt-shift-t in AeroSpace)
```

Switching never modifies tracked files. bar/borders/wallpaper change instantly;
terminal/editor/TUIs adopt the theme on next launch. Add a theme by dropping a
new `<name>.toml` in the themes dir.
```

- [ ] **Step 5: Full clean verification**

Run:
```bash
make test-theme
~/.local/bin/theme-set --init
git -C ~/.dotfiles status --porcelain
```
Expected: tests pass; `--init` applies a theme; the only pending git changes are this task's edits (no theme-state churn).

- [ ] **Step 6: Commit**

```bash
git add install.sh Makefile .gitignore README.md
git commit -m "feat(theme): bootstrap theming in install.sh, register packages, document"
```

---

## Self-Review

**Spec coverage:**
- Unified theming system (manifest + generator → state dir) → Tasks 1-11. ✓
- Seed themes Gruvbox + Tokyo Night → Tasks 1, 2+ (golden tests both). ✓
- Per-app propagation: sketchybar (T3), borders (T4), ghostty (T5), lazygit (T6), nvim (T7), btop (T8), starship (T9), wallpaper (T10). ✓
- Clean-git invariant → enforced/verified in T3, T11. ✓
- theme-set / theme-list / cycle / keybind → T3, T10. ✓
- Font coherence CaskaydiaMono → T12. ✓
- TUIs btop/lazydocker/dust/procs → T8 (btop), T13. ✓
- Bootstrap + stow registration + docs → T14. ✓
- Out of scope (app-launch binds, leader menu) → correctly omitted. ✓

**Placeholder scan:** No TBD/TODO. Verification-with-fallback steps (ghostty theme name T5.1, CaskaydiaMono cask name T12.1, lazygit `--print-config` T6.7, sketchybar glyphs T12.5) are explicit checks with defined fallbacks, not placeholders.

**Type/name consistency:** `manifest_get`, `load_palette`, and palette role globals are defined in T1 and reused unchanged. Generator functions `gen_sketchybar/gen_borders/gen_ghostty/gen_lazygit/gen_nvim/gen_btop/gen_starship` keep consistent signatures across the tasks that add them and the `theme-set` calls in T3-T10. `gen_check` (T2) forwards its 4th arg as `$1` to the gen function, consistent with `gen_ghostty`/`gen_nvim` (manifest path) and `gen_btop` (display title). State dir path `${XDG_STATE_HOME:-$HOME/.local/state}/theme` is identical everywhere.

**Known risks carried from the spec (each has a verify step):** Ghostty live reload (next-window, documented); lazygit `LG_CONFIG_FILE` merge (T6.7 verify); btop `--no-folding` dir (T8.6 verify); CaskaydiaMono glyph coverage (T12.5 verify + fallback).
