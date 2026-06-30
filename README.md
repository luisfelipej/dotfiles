# dotfiles

Personal macOS dotfiles managed with [GNU Stow](https://www.gnu.org/software/stow/).

## Quick Start

```bash
git clone git@github.com:luisfelipej/dotfiles.git ~/.dotfiles
cd ~/.dotfiles
./install.sh
```

## Packages

| Package | Contents |
|---------|----------|
| `sketchybar` | Status bar configuration (`~/.config/sketchybar/`) |
| `nvim` | Neovim configuration (`~/.config/nvim/`) |
| `fish` | Fish shell config, functions, and plugins (`~/.config/fish/`) |
| `ghostty` | Ghostty terminal configuration (`~/.config/ghostty/`) |
| `tmux` | Tmux configuration (`~/.tmux.conf`) |
| `claude` | Claude Code settings, MCP servers, and agents (`~/.claude/`) |
| `theme` | Theme manifests, generator lib, and `theme-set`/`theme-list` bins (`~/.local/bin/`) |
| `btop` | btop++ configuration (`~/.config/btop/`); stowed with `--no-folding` so `themes/` is a real dir |

## Sync Workflow

```bash
# Pull latest changes
cd ~/.dotfiles && git pull

# Push local changes
cd ~/.dotfiles && git add -A && git commit -m "update" && git push
```

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

## Makefile Targets

| Target | Description |
|--------|-------------|
| `make stow` | Create symlinks for all packages |
| `make stow-btop` | Stow btop with `--no-folding` (run after `make stow` on first setup) |
| `make unstow` | Remove symlinks for all packages |
| `make restow` | Re-create symlinks (useful after changes) |
| `make adopt` | Adopt existing files into stow packages |
| `make status` | Show current symlink status |
| `make test-theme` | Run theming system tests |
