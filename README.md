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
| `claude` | Portable Claude Code assets and a settings example (`~/.claude/`) |

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

## Claude Code Settings Boundary

The `claude` package does not manage `~/.claude/settings.json`. That file is the
Claude Code user-settings scope, so it remains a regular machine-local file.
`claude/.claude/settings.example.json` contains the portable baseline to review
when creating or updating user settings. It contains no credentials, runtime
state, or absolute user paths.

Claude Code currently supports these editable settings scopes:

| Scope | Supported path | Repository policy |
|-------|----------------|-------------------|
| User | `~/.claude/settings.json` | Machine-local; never stowed |
| Shared project | `<project>/.claude/settings.json` | Commit only project-wide settings |
| Project local | `<project>/.claude/settings.local.json` | Keep local and untracked |

There is no documented `~/.claude/settings.local.json` user override. Put a
personal override for one repository in that repository's
`.claude/settings.local.json`. User-wide machine-specific preferences must live
in `~/.claude/settings.json`.

Claude Code also writes credentials and per-project state to `~/.claude.json`
and runtime data below `~/.claude/`. Neither belongs in this repository. The
Stow wrapper creates `~/.claude` as a real directory after the global preflight
succeeds, then links only the managed leaves. This prevents a fresh install
from redirecting later state writes into the dotfiles repository.

When an older install folded the whole directory into the package, the wrapper
uses Git to classify every untracked and ignored file below
`claude/.claude/`. It unfolds the directory and moves those local files back to
the same paths under `~/.claude/` before applying either `restow` or `unstow`.
Tracked managed files remain in the repository. If the package is not a Git
worktree or a path cannot be classified safely, migration aborts before the
directory symlink is changed. `unstow` preserves migrated local state but does
not create `~/.claude` when it was absent.

During `stow`, `restow`, or explicit adoption, the wrapper also migrates the
legacy user-settings link left by this repository. If
`~/.claude/settings.json` is dangling and resolves exactly to the former
`claude/.claude/settings.json` package path, the wrapper replaces it with a
regular local copy of `settings.example.json`. During `unstow`, it only removes
that exact obsolete link and does not create settings. No mode changes a
regular settings file, a valid symlink, or a dangling symlink owned by anything
else. A fresh home still receives no implicit `settings.json`.

References: [Claude Code settings scopes and precedence](https://code.claude.com/docs/en/settings),
[settings reference](https://code.claude.com/docs/en/settings-reference), and
[the `.claude` directory](https://code.claude.com/docs/en/claude-directory).

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
