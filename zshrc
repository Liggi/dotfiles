# Path to your oh-my-zsh installation.
export ZSH=$HOME/.oh-my-zsh

# Plugins: git (aliases), brew (completions), node (JS/TS dev),
# zsh-autosuggestions (fish-like suggestions), zsh-syntax-highlighting (color feedback)
plugins=(git brew node zsh-autosuggestions zsh-syntax-highlighting)

# User configuration - PATH Management

# System paths (base)
export PATH="/usr/local/bin:/usr/bin:/bin:/usr/sbin:/sbin"

# Add Homebrew 
export PATH="/opt/homebrew/bin:$PATH"

# Add specialized tools
export PATH="/opt/homebrew/opt/libpq/bin:$PATH"       # PostgreSQL tools

source $ZSH/oh-my-zsh.sh

# Runtime/toolchain manager (global)
if command -v mise >/dev/null 2>&1; then
  eval "$(mise activate zsh)"
fi

# direnv (future per-repo envs; harmless without .envrc)
if command -v direnv >/dev/null 2>&1; then
  eval "$(direnv hook zsh)"
fi

# Editor setup - Use Neovim
if command -v nvim >/dev/null 2>&1; then
  export EDITOR=nvim
  alias vim=nvim
  alias vi=nvim
else
  export EDITOR=vim
fi

# Load environment variables and API keys
. "$HOME/.local/bin/env"

eval "$(starship init zsh)"
[ -f ~/.fzf.zsh ] && source ~/.fzf.zsh

# Modern CLI tool initialization
eval "$(zoxide init zsh)" 
source /Users/jasonliggi/.config/broot/launcher/bash/br

# Modern CLI tool aliases
alias cat="bat"
alias ls="eza --icons --group-directories-first"
alias ll="eza -l --icons --group-directories-first"
alias la="eza -la --icons --group-directories-first"  
alias tree="eza --tree --icons"
alias find="fd"
alias grep="rg"
alias du="dust"

# Enhanced FZF integration with modern tools
export FZF_DEFAULT_COMMAND="fd --type f --color=never"
export FZF_CTRL_T_COMMAND="$FZF_DEFAULT_COMMAND"
export FZF_ALT_C_COMMAND="fd --type d . --color=never"
export FZF_CTRL_T_OPTS="--preview 'bat --color=always --style=numbers --line-range :300 {}'"
export FZF_ALT_C_OPTS="--preview 'eza --tree --color=always {} | head -200'"
export FZF_CTRL_R_OPTS="--preview 'echo {}' --preview-window up:3:hidden:wrap --bind '?:toggle-preview'"

# Lazygit with directory sync
lg() {
    export LAZYGIT_NEW_DIR_FILE=~/.lazygit/newdir
    lazygit "$@"
    if [ -f $LAZYGIT_NEW_DIR_FILE ]; then
        cd "$(cat $LAZYGIT_NEW_DIR_FILE)"
        rm -f $LAZYGIT_NEW_DIR_FILE > /dev/null
    fi
}

# Personal scripts
export PATH="$HOME/bin:$PATH"
export PATH="$HOME/.local/bin:$PATH"
export PATH="$HOME/claudefiles/bin:$PATH"
export PATH="$HOME/codexfiles/bin:$PATH"

if [[ -n "$TMUX" ]]; then
    bindkey -s '^L' ''
fi

. "$HOME/.atuin/bin/env"

eval "$(atuin init zsh)"
