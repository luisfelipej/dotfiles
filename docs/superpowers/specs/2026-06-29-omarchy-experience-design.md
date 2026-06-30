# Omarchy-style Experience for macOS dotfiles — Design

**Date:** 2026-06-29
**Branch:** `feat/omarchy-experience`
**Status:** Approved (design phase)

## Goal

Bring the macOS dotfiles closer to the feel of [Omarchy](https://omarchy.org)
(DHH's opinionated Hyprland distro) by introducing the trait that most defines
it: a **unified, single-source theming system** that switches the whole
environment with one command — plus the supporting coherence (one Nerd Font)
and the TUI tooling Omarchy takes for granted.

The current stack is already the macOS mirror of Omarchy (AeroSpace ≈ Hyprland,
JankyBorders ≈ HL borders, SketchyBar ≈ Waybar, Ghostty, Neovim, Raycast ≈
Walker). What is missing is the *coherence layer*: today the theme is replicated
by hand across 4+ files (the accent `e78a4e` lives in ghostty, borders,
sketchybar, and lazygit independently).

## Scope

**In scope:**

1. Unified theming system (manifest + generator), seeded with **Gruvbox
   Material** and **Tokyo Night**.
2. Font coherence: standardize on **CaskaydiaMono Nerd Font**.
3. New TUIs: **btop, lazydocker, dust, procs** (btop themed by the system).
4. Wallpaper tied to the active theme.
5. One theme-switch keybind in AeroSpace.

**Out of scope (deferred to later changes):**

- App-launch keybindings ("Super"-style binds to open terminal/browser/music).
- A leader / command menu (omarchy-menu analog via Raycast or an AeroSpace mode).

## Architecture

### Core principle: generated output never touches tracked configs

The single hardest constraint with a generator + Stow + Git is **git churn**:
if `theme-set` rewrote the tracked `sketchybar/colors.sh`, every theme switch
would dirty the repo. The design avoids this entirely.

```
themes/*.toml            (in repo — single source of truth)
      │
      ▼  theme-set <name>   (generates; never writes into tracked configs)
~/.local/state/theme/    (gitignored — runtime state)
      ├── sketchybar.sh        apps SOURCE / READ these fragments,
      ├── borders.env          not the tracked config files
      ├── ghostty.conf
      ├── lazygit.yml
      ├── btop.theme
      ├── starship-palette
      └── current              ← active theme name
```

The generator reads a theme manifest and writes per-app fragments into a
gitignored state directory. Each app is wired to **source/read** from that
directory. Switching themes any number of times leaves Git clean. This mirrors
how Omarchy works (`~/.config/omarchy/current/theme`).

### The manifest (single source of truth)

One TOML file per theme under `theme/.config/theme/themes/`. It declares, once,
what today is duplicated across apps:

```toml
name = "gruvbox-material"
wallpaper = "gruvbox-forest.jpg"   # resolved against the wallpapers/ package

[palette]                          # semantic roles, not per-app color names
bg       = "282828"
bg_alt   = "32302f"
fg       = "d4be98"
fg_muted = "a89984"
accent   = "e78a4e"                # the orange currently hardcoded x4
red      = "ea6962"
green    = "a9b665"
yellow   = "d8a657"
blue     = "7daea3"
aqua     = "89b482"
purple   = "d3869b"

[native]                           # where an app ships the theme built-in,
ghostty = "Gruvbox Material Dark"  # we set its native name instead of raw colors
nvim    = "gruvbox-material"
```

Color values are stored as bare `RRGGBB` hex. The generator derives each app's
required format from these (e.g. `0xff` + hex for sketchybar/borders, `#` + hex
for lazygit/btop).

### Propagation per app

| App | Wiring | Reload | Live? |
|---|---|---|---|
| sketchybar | `sketchybarrc` sources `state/sketchybar.sh` (replaces tracked `colors.sh` role) | `sketchybar --reload` | ✅ instant |
| borders | `bordersrc` reads `state/borders.env` (`ACTIVE_COLOR`, `INACTIVE_COLOR`) | relaunch `borders` | ✅ instant |
| starship | `starship.toml` defines `[palettes.*]` for both themes; theme-set flips top-level `palette = "..."` | per-prompt | ✅ instant |
| wallpaper | `osascript` (set picture of every desktop) or `wallpaper` CLI | — | ✅ instant |
| ghostty | `config` includes `state/ghostty.conf` via `config-file`; fragment sets the `native` theme name | new windows / manual reload | ⚠️ next launch |
| lazygit | `LG_CONFIG_FILE=~/.config/lazygit/config.yml,~/.local/state/theme/lazygit.yml` (native merge); fragment carries only the theme block | — | ⚠️ next launch |
| nvim | reads active theme name at startup (with fallback to a default colorscheme) | — | ⚠️ next launch |
| btop | `btop.conf` `color_theme` flipped + generated `.theme` file | — | ⚠️ next launch |

**Honest trade-off:** bar, borders, prompt, and wallpaper change instantly;
terminal, editor, and TUIs adopt the theme on next launch. This is the same
reality Omarchy has with several apps. We will not claim full live re-theming.

### Theme-switch UX

- `theme-set <name>` — applies a theme (generate fragments → reload instant
  apps). Idempotent.
- `theme-list` — lists available themes; marks the current one.
- Both shipped as scripts on `PATH` via `theme/.local/bin/` (ensure `~/.local/bin`
  is on fish's PATH; add it if missing).
- AeroSpace keybind `alt-shift-t` cycles to the next theme. This is the **only**
  new keybind in this change (it belongs to the switching UX, not the deferred
  app-launch scope).

### Implementation language

The generator and `theme-set` are written in **bash** (portable; sketchybar and
borders configs are already shell). They are invoked from fish via PATH. No
fish-specific logic in the core generator.

## Components / package layout

Two new Stow packages:

```
theme/
  .local/bin/
    theme-set                # apply a theme
    theme-list               # list themes / show current
  .config/theme/
    themes/
      gruvbox-material.toml
      tokyo-night.toml
    lib/
      generate.sh            # manifest -> per-app fragments (the testable unit)

btop/
  .config/btop/
    btop.conf                # color_theme points at the active theme
    themes/
      gruvbox-material.theme
      tokyo-night.theme
```

Modified existing files:

- `sketchybar/.config/sketchybar/sketchybarrc` — source `state/sketchybar.sh`
  when present, else fall back to the committed `colors.sh`. `colors.sh` stays in
  the repo as the bootstrap default (Gruvbox), so a fresh machine renders
  correctly before `theme-set` has ever run.
- `borders/.config/borders/bordersrc` — read `state/borders.env`.
- `ghostty/.config/ghostty/config` — add `config-file` include of
  `state/ghostty.conf`; switch `font-family` to CaskaydiaMono.
- `starship/.config/starship.toml` — add `[palettes.*]` for both themes.
- `lazygit` — theme block moves to a generated fragment; base config keeps the
  rest. `LG_CONFIG_FILE` set in fish config.
- `nvim/.config/nvim/lua/plugins/colorscheme.lua` — read active theme name at
  startup with a safe fallback.
- `aerospace/.aerospace.toml` — add `alt-shift-t` cycle binding.
- `fish` config — `LG_CONFIG_FILE`, ensure `~/.local/bin` on PATH, optional
  abbreviations (`lzd` → lazydocker).
- `Brewfile` — add `cask "font-caskaydia-mono-nerd-font"`, `brew "btop"`,
  `brew "lazydocker"`, `brew "dust"`, `brew "procs"`.
- `.gitignore` — nothing new needed for state (it lives under `~/.local/state`,
  outside the repo), but document the state dir location.

### Bootstrap / first-run

`install.sh` (or `make stow`) must run `theme-set` once with a default theme so
the state fragments exist before apps start. Apps that source a missing state
file must degrade gracefully (the sketchybarrc/bordersrc source line guards for
a missing file and falls back to a committed default).

## Font coherence

- Add `cask "font-caskaydia-mono-nerd-font"` to the Brewfile. (Verify the exact
  cask name at implementation — Omarchy ships "CaskaydiaMono Nerd Font".)
- Point `font-family` (ghostty) and `ICON_FONT` + `LABEL_FONT` (sketchybar) to
  `CaskaydiaMono Nerd Font` / `CaskaydiaMono Nerd Font Mono`.
- Verify Nerd-Font glyph coverage for the existing sketchybar icons (CaskaydiaMono
  is a patched Nerd Font, so coverage is expected; confirm visually).
- Optional, flagged as separate cleanup: prune unused font casks (Hack, Meslo,
  Monaspace) and the stale `ghostty/config.eyes.bak`.

## TUIs

- Brewfile: `btop`, `lazydocker`, `dust`, `procs`.
- `btop` is wired into the theming system (new `btop/` package with `.theme`
  files for both seed themes).
- `dust` / `procs` need no config.
- Optional: fish abbreviation `lzd` → `lazydocker`.

## Testing

The generator (`lib/generate.sh`) is the only piece with real logic, and it is a
near-pure transform (`manifest.toml` → fragment text). This is the testable
boundary:

1. **Golden tests:** for each seed theme and each app fragment, `generate.sh`
   output matches a committed golden file.
2. **Validity:** each generated fragment parses as valid TOML/YAML/conf (or, for
   shell fragments, `bash -n` passes).
3. **Idempotency:** running `theme-set <name>` twice yields byte-identical state.

Tests run as a shell test script (e.g. `theme/.config/theme/lib/test.sh` or a
`make test-theme` target) — no app launch required.

## Risks / open questions

- **ghostty live reload:** Ghostty has no clean CLI to reload config; the theme
  applies on new windows or manual reload. Acceptable per the trade-off above.
- **lazygit `LG_CONFIG_FILE` merge:** relies on lazygit's documented
  comma-separated config merge — verify behavior at implementation.
- **CaskaydiaMono cask name:** confirm exact Homebrew cask identifier.
- **sketchybar icon glyphs:** confirm CaskaydiaMono renders the current icon set.

## Definition of done

- `theme-set gruvbox-material` and `theme-set tokyo-night` both apply cleanly;
  bar/borders/prompt/wallpaper change instantly, other apps on next launch.
- Switching themes leaves `git status` clean.
- The accent color is defined in exactly one place per theme (the manifest).
- All configs render in CaskaydiaMono Nerd Font.
- btop, lazydocker, dust, procs installed; btop themed by the system.
- Generator golden/validity/idempotency tests pass.
