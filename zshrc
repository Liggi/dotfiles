# Path to your oh-my-zsh installation.
export ZSH=$HOME/.oh-my-zsh

# Note: Using Starship prompt instead of oh-my-zsh themes (see starship init below)


# Plugins: git (aliases), brew (completions), node (JS/TS dev),
# zsh-autosuggestions (fish-like suggestions), zsh-syntax-highlighting (color feedback)
plugins=(git brew node zsh-autosuggestions zsh-syntax-highlighting)

# User configuration - PATH Management

# System paths (base)
export PATH="/usr/local/bin:/usr/bin:/bin:/usr/sbin:/sbin"

# Add Homebrew 
export PATH="/opt/homebrew/bin:$PATH"

# Add specialized tools
export PATH="/opt/homebrew/opt/openjdk@11/bin:$PATH"  # Java 11
export PATH="/opt/homebrew/opt/libpq/bin:$PATH"       # PostgreSQL tools

# Add your Go workspace
export PATH="$PATH:$HOME/go/bin"

source $ZSH/oh-my-zsh.sh

# Editor setup - Use Neovim
if command -v nvim >/dev/null 2>&1; then
  export EDITOR=nvim
  alias vim=nvim
  alias vi=nvim
else
  export EDITOR=vim
fi

# Add Rust/Cargo tools
export PATH="$HOME/.cargo/bin:$PATH"

# Node.js version management
export NVM_DIR="$HOME/.nvm"
[ -s "/opt/homebrew/opt/nvm/nvm.sh" ] && \. "/opt/homebrew/opt/nvm/nvm.sh"
[ -s "/opt/homebrew/opt/nvm/etc/bash_completion.d/nvm" ] && \. "/opt/homebrew/opt/nvm/etc/bash_completion.d/nvm"

# Go private modules
export GOPRIVATE=github.com/gradientlabs-ai/wearegradient

# pnpm setup
export PNPM_HOME="/Users/jasonliggi/Library/pnpm"
case ":$PATH:" in
  *":$PNPM_HOME:"*) ;;
  *) export PATH="$PNPM_HOME:$PATH" ;;
esac
# Custom database connection function
db() { pgcli $(encore db conn-uri platform | sed 's/localhost/127.0.0.1/') }

# Load environment variables and API keys
. "$HOME/.local/bin/env"

eval "$(starship init zsh)"
[ -f ~/.fzf.zsh ] && source ~/.fzf.zsh

function dev() {
  ROOT_1="$HOME/src/github.com/gradientlabs-ai"
  ROOT_2="$HOME/src/github.com/gradientlabs-ai-two"

  workspace=$(printf "Workspace One\nWorkspace Two" | fzf --prompt="Select a workspace: ")

  if [ -z "$workspace" ]; then
    echo "No selection"
    return 1
  fi

  if [[ "$workspace" == "Workspace One" ]]; then
    export WORKSPACE=1
    cd "$ROOT_1"
  else
    export WORKSPACE=2
    cd "$ROOT_2"
  fi
}

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

# Productivity shortcuts  
alias help="tldr"

# Enhanced git workflow
alias gdiff="git diff"  # Uses delta (already configured)
alias glog="git log --oneline --graph --decorate"

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

# pnpm productivity aliases (since you use pnpm)
alias pi="pnpm install"
alias pa="pnpm add"
alias pad="pnpm add -D"
alias pr="pnpm run"
alias px="pnpx"

# Personal scripts
export PATH="$HOME/bin:$PATH"
