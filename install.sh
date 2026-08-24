#!/usr/bin/env bash
set -euo pipefail

DOTFILES_DIR="$HOME/.dotfiles"
REPO="git@github.com:luisfelipej/dotfiles.git"

echo "==> Dotfiles Bootstrap"

# 1. Install Homebrew if missing
if ! command -v brew &>/dev/null; then
    echo "Installing Homebrew..."
    /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
    eval "$(/opt/homebrew/bin/brew shellenv)"
fi

# 2. Install GNU Stow if missing
if ! command -v stow &>/dev/null; then
    echo "Installing GNU Stow..."
    brew install stow
fi

# 3. Clone dotfiles if not present
if [ ! -d "$DOTFILES_DIR" ]; then
    echo "Cloning dotfiles..."
    git clone "$REPO" "$DOTFILES_DIR"
fi

cd "$DOTFILES_DIR"

# 4. Preflight all packages before migration or other filesystem changes
PACKAGES=(sketchybar nvim fish ghostty tmux claude git starship mise)
STOW_PREFLIGHT_ONLY=1 bash "$DOTFILES_DIR/stow.sh" restow "${PACKAGES[@]}"

# 5. Ghostty XDG migration (move App Support config if it exists)
GHOSTTY_APP_SUPPORT="$HOME/Library/Application Support/com.mitchellh.ghostty"
if [ -f "$GHOSTTY_APP_SUPPORT/config" ] && [ ! -L "$HOME/.config/ghostty/config" ]; then
    echo "Migrating Ghostty config to XDG path..."
    mv "$GHOSTTY_APP_SUPPORT/config" "$GHOSTTY_APP_SUPPORT/config.migrated.bak"
fi

# 6. Preflight again and stow all packages (restow mode for idempotency)
bash "$DOTFILES_DIR/stow.sh" restow "${PACKAGES[@]}"

# 7. Install Homebrew packages from the Brewfile
if [ -f "$DOTFILES_DIR/Brewfile" ]; then
    echo "Installing Homebrew bundle..."
    brew bundle --file="$DOTFILES_DIR/Brewfile"
fi

# 8. Install TPM if missing
TPM_DIR="$HOME/.tmux/plugins/tpm"
if [ ! -d "$TPM_DIR" ]; then
    echo "Installing TPM..."
    git clone https://github.com/tmux-plugins/tpm "$TPM_DIR"
    echo "Run 'prefix + I' in tmux to install plugins"
fi

# 9. Install Fisher if missing without loading interactive shell configuration
FISH_CONFIG_DIR="${XDG_CONFIG_HOME:-$HOME/.config}/fish"
if [ ! -f "$FISH_CONFIG_DIR/functions/fisher.fish" ]; then
    echo "Installing Fisher..."
    fish --no-config -c "curl -sL https://raw.githubusercontent.com/jorgebucaran/fisher/main/functions/fisher.fish | source && fisher install jorgebucaran/fisher"
    echo "Run 'fisher update' in fish to install plugins"
fi

echo "==> Done! Restart your terminal."
