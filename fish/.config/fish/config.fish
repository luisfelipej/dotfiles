# Detect Termux
set -l IS_TERMUX 0
if test -n "$TERMUX_VERSION"; or test -d /data/data/com.termux
    set IS_TERMUX 1
end

if test $IS_TERMUX -eq 1
    # Termux - use PREFIX for binaries
    fish_add_path --global --move $PREFIX/bin $HOME/.local/bin $HOME/.cargo/bin
else if test (uname) = Darwin
    # Check both Homebrew locations because GUI terminals may have a minimal PATH.
    if type -q brew
        set BREW_BIN (command -s brew)
    else if test -x /opt/homebrew/bin/brew
        set BREW_BIN /opt/homebrew/bin/brew
    else if test -x /usr/local/bin/brew
        set BREW_BIN /usr/local/bin/brew
    end
    fish_add_path --global --move $HOME/.local/bin $HOME/.opencode/bin $HOME/.volta/bin $HOME/.bun/bin $HOME/.nix-profile/bin /nix/var/nix/profiles/default/bin /usr/local/bin $HOME/.cargo/bin
else
    # Linux
    if type -q brew
        set BREW_BIN (command -s brew)
    else if test -x /home/linuxbrew/.linuxbrew/bin/brew
        set BREW_BIN /home/linuxbrew/.linuxbrew/bin/brew
    end
    fish_add_path --global --move $HOME/.local/bin $HOME/.opencode/bin $HOME/.volta/bin $HOME/.bun/bin $HOME/.nix-profile/bin /nix/var/nix/profiles/default/bin /usr/local/bin $HOME/.cargo/bin
end

# Load Homebrew's environment once when it is installed.
if test $IS_TERMUX -eq 0; and set -q BREW_BIN
    eval ($BREW_BIN shellenv)
end

set -gx CARAPACE_BRIDGES 'zsh,fish,bash,inshellisense'

if status is-interactive
    fish_vi_key_bindings

    abbr --add k kubectl
    abbr --add kcc kubectl config use-context
    abbr --add kcc-keiron-dev kubectl config use-context arn:aws:eks:us-east-1:872535834453:cluster/DevEKSA50EF4AB-65ba17bfbc944963882af83ef572e3cf
    abbr --add kcc-keiron-prod kubectl config use-context arn:aws:eks:us-east-1:872535834453:cluster/ProdEKSED1809F8-ea6f31fc83a6469294175c9bcc990939
    abbr --add t tmux
    abbr --add tks tmux kill-session -t
    abbr --add n nvim

    if type -q starship
        starship init fish | source
    end
    if type -q zoxide
        zoxide init fish | source
    end
    if type -q atuin
        atuin init fish | source
    end
    if type -q fzf
        fzf --fish | source
    end
    if type -q carapace
        carapace _carapace fish | source
    end
end

if type -q mise
    mise activate fish | source
end

set -g fish_greeting ""

# Set nvim as the default editor for OpenCode and other tools.
set -gx EDITOR nvim
set -gx VISUAL nvim

## alias
if test (uname) = Darwin
    alias ls='ls --color=auto'
else
    alias ls='gls --color=auto'
end

alias fzfbat='fzf --preview="bat --theme=gruvbox-dark --color=always {}"'
alias fzfnvim='nvim (fzf --preview="bat --theme=gruvbox-dark --color=always {}")'

set -l foreground F3F6F9 normal
set -l selection 263356 normal
set -l comment 8394A3 brblack
set -l red CB7C94 red
set -l orange DEBA87 orange
set -l yellow FFE066 yellow
set -l green B7CC85 green
set -l purple A3B5D6 purple
set -l cyan 7AA89F cyan
set -l pink FF8DD7 magenta

# Syntax Highlighting Colors
set -g fish_color_normal $foreground
set -g fish_color_command $cyan
set -g fish_color_keyword $pink
set -g fish_color_quote $yellow
set -g fish_color_redirection $foreground
set -g fish_color_end $orange
set -g fish_color_error $red
set -g fish_color_param $purple
set -g fish_color_comment $comment
set -g fish_color_selection --background=$selection
set -g fish_color_search_match --background=$selection
set -g fish_color_operator $green
set -g fish_color_escape $pink
set -g fish_color_autosuggestion $comment

# Completion Pager Colors
set -g fish_pager_color_progress $comment
set -g fish_pager_color_prefix $cyan
set -g fish_pager_color_completion $foreground
set -g fish_pager_color_description $comment
