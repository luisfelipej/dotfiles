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
| `make adopt` | Explicitly adopt existing files after preview and backup |
| `make status` | Show current symlink status |

`stow`, `restow`, and the installer preflight every package before making any
filesystem changes. A conflict aborts the complete operation; existing files
are never adopted by these normal flows.

## Explicit Adoption

Adoption overwrites package files with their existing counterparts from
`HOME`. Package paths must be clean in Git. Choose a new backup path outside
the repository and outside any path managed by these packages:

```bash
ADOPT_BACKUP="$HOME/dotfiles-adopt-$(date +%Y%m%d-%H%M%S).tar.gz"
STOW_ADOPT_BACKUP="$ADOPT_BACKUP" make adopt
```

The command first prints GNU Stow's complete dry-run plan. Inspect the listed
paths, then type `adopt` exactly to continue. For non-interactive use, the same
explicit confirmation can be supplied with `STOW_ADOPT_CONFIRM=adopt`.

After adoption, inspect the result with `git diff`. To return to the exact
pre-adoption state, unstow the packages, restore the previously clean package
paths from Git with the exact `git restore` command printed by `make adopt`,
and extract the backup into `HOME`:

```bash
make unstow
# Run the exact git restore command printed after adoption.
tar -xzf "$ADOPT_BACKUP" -C "$HOME"
```

The restored files in `HOME` are regular files again, so a later normal stow
will report them as conflicts rather than adopting them implicitly.
