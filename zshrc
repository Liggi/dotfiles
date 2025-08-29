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
  if [ -n "$TMUX" ]; then
    tmux split-window -h \; select-pane -L \; split-window -v \; \
         select-pane -t 1 \; select-pane -T "Amp" \; \
         select-pane -t 2 \; select-pane -T "Claude Code" \; \
         select-pane -t 3 \; select-pane -T "Neovim / Terminal"
  else
    tmux new-session \; split-window -h \; select-pane -L \; split-window -v \; \
         select-pane -t 1 \; select-pane -T "Amp" \; \
         select-pane -t 2 \; select-pane -T "Claude Code" \; \
         select-pane -t 3 \; select-pane -T "Neovim / Terminal"
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
alias du="dust"

# Productivity shortcuts  
alias help="tldr"

# Enhanced git workflow
unset -f gdiff 2>/dev/null; unalias gdiff 2>/dev/null
gdiff() {
  if [ -n "$TMUX" ]; then
    local current_pane=$(tmux display-message -p '#{pane_id}')
    tmux select-pane -t "$current_pane"
    tmux resize-pane -Z
  fi
  
  nvim -c 'DiffviewOpen'
  
  if [ -n "$TMUX" ]; then
    tmux resize-pane -Z
  fi
}
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
export PATH="$HOME/.local/bin:$PATH"
export PATH="$HOME/claudefiles/bin:$PATH"

if [[ -n "$TMUX" ]]; then
    bindkey -s '^L' ''
fi

check-webapp() {
    local current_dir=$(pwd)
    
    cd ~/src/github.com/gradientlabs-ai/web-app
    
    echo "🔍 Running web app checks..."
    echo
    
    echo "📦 Installing dependencies..."
    pnpm install
    echo
    
    echo "🔧 Building packages..."
    pnpm build:packages || { echo "❌ Build packages failed"; cd "$current_dir"; return 1; }
    echo
    
    cd apps/web-app
    echo "🔍 Switched to $(pwd) for app-specific checks..."
    echo
    
    echo "🧹 Running linter with auto-fix..."
    pnpm lint --fix || { echo "❌ Lint failed"; cd "$current_dir"; return 1; }
    echo
    
    echo "💅 Auto-fixing formatting..."
    pnpm prettier --write . || { echo "❌ Formatting failed"; cd "$current_dir"; return 1; }
    echo
    
    echo "🔍 Running type check..."
    pnpm typecheck || { echo "❌ Type check failed"; cd "$current_dir"; return 1; }
    echo
    
    echo "🧪 Running tests..."
    pnpm test:ci || { echo "❌ Tests failed"; cd "$current_dir"; return 1; }
    echo
    
    echo "✅ All checks passed!"
    
    cd "$current_dir"
}

. "$HOME/.atuin/bin/env"

eval "$(atuin init zsh)"
export PATH="$HOME/codexfiles/bin:$PATH"
