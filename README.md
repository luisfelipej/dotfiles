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

## Sync Workflow

```bash
# Pull latest changes
cd ~/.dotfiles && git pull

# Push local changes
cd ~/.dotfiles && git add -A && git commit -m "update" && git push
```

## Makefile Targets

| Target | Description |
|--------|-------------|
| `make stow` | Create symlinks for all packages |
| `make unstow` | Remove symlinks for all packages |
| `make restow` | Re-create symlinks (useful after changes) |
| `make adopt` | Adopt existing files into stow packages |
| `make status` | Show current symlink status |
