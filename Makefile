PACKAGES = sketchybar nvim fish ghostty tmux claude git starship mise lf aerospace borders lazygit
MAKEFILE_DIR := $(dir $(abspath $(lastword $(MAKEFILE_LIST))))
STOW_SCRIPT := $(MAKEFILE_DIR)stow.sh

.PHONY: stow unstow restow adopt status

stow:
	@bash "$(STOW_SCRIPT)" stow $(PACKAGES)

unstow:
	@bash "$(STOW_SCRIPT)" unstow $(PACKAGES)

restow:
	@bash "$(STOW_SCRIPT)" restow $(PACKAGES)

adopt:
	@bash "$(STOW_SCRIPT)" adopt $(PACKAGES)

status:
	@echo "Symlink status:"
	@ls -la ~/.config/nvim 2>/dev/null || echo "nvim: NOT stowed"
	@ls -la ~/.config/ghostty 2>/dev/null || echo "ghostty: NOT stowed"
	@ls -la ~/.config/fish 2>/dev/null || echo "fish: NOT stowed"
	@ls -la ~/.config/sketchybar 2>/dev/null || echo "sketchybar: NOT stowed"
	@ls -la ~/.tmux.conf 2>/dev/null || echo "tmux: NOT stowed"
	@ls -la ~/.claude/settings.json 2>/dev/null || echo "claude: NOT stowed"
