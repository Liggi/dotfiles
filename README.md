# dotfiles ⚫

## What's included

### Git config (`gitconfig`)
Git aliases, settings, and user info

### Zsh config (`zshrc`)
- Oh-My-Zsh with plugins (autosuggestions, syntax highlighting)
- Starship prompt for enhanced shell experience
- CLI tool aliases (bat, eza, fd, ripgrep, lazygit)
- Development environment setup (NVM, Go, Rust, pnpm)
- Custom functions for tmux layouts and productivity workflows
- Enhanced FZF integration with previews

### Neovim config (`nvim/init.lua`)
- Setup with lazy.nvim plugin manager
- LSP configuration with Mason for language servers
- Telescope for fuzzy finding
- Treesitter for syntax highlighting
- Git integration with gitsigns and diffview
- Auto-completion with nvim-cmp

### Tmux config (`tmux.conf`)
- Ctrl+Space prefix for better ergonomics
- Vim-aware pane navigation
- Mouse support and custom key bindings
- Enhanced status bar and color scheme

## Installation

```bash
git clone https://github.com/Liggi/dotfiles.git ~/dotfiles
cd ~/dotfiles
./scripts/install
```

