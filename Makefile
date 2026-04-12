PACKAGES = sketchybar nvim fish ghostty tmux claude

.PHONY: stow unstow restow adopt status

stow:
	@for pkg in $(PACKAGES); do \
		echo "Stowing $$pkg..."; \
		stow -t ~ $$pkg; \
	done

unstow:
	@for pkg in $(PACKAGES); do \
		echo "Unstowing $$pkg..."; \
		stow -D -t ~ $$pkg; \
	done

restow:
	@for pkg in $(PACKAGES); do \
		echo "Restowing $$pkg..."; \
		stow -R -t ~ $$pkg; \
	done

adopt:
	@for pkg in $(PACKAGES); do \
		echo "Adopting $$pkg..."; \
		stow --adopt -t ~ $$pkg; \
	done

status:
	@echo "Symlink status:"
	@ls -la ~/.config/nvim 2>/dev/null || echo "nvim: NOT stowed"
	@ls -la ~/.config/ghostty 2>/dev/null || echo "ghostty: NOT stowed"
	@ls -la ~/.config/fish 2>/dev/null || echo "fish: NOT stowed"
	@ls -la ~/.config/sketchybar 2>/dev/null || echo "sketchybar: NOT stowed"
	@ls -la ~/.tmux.conf 2>/dev/null || echo "tmux: NOT stowed"
	@ls -la ~/.claude/settings.json 2>/dev/null || echo "claude: NOT stowed"
