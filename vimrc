set nocompatible
filetype off

set rtp+=~/.vim/bundle/Vundle.vim
call vundle#begin()

Plugin 'gmarik/Vundle.vim'

Plugin 'altercation/vim-colors-solarized'

Plugin 'vim-scripts/ZoomWin'

Plugin 'tpope/vim-fugitive'
Plugin 'tpope/vim-repeat'
Plugin 'tpope/vim-surround'

Plugin 'kien/ctrlp.vim'
Plugin 'rking/ag.vim'

Plugin 'ddollar/nerdcommenter'

Plugin 'scrooloose/nerdtree'
Plugin 'scrooloose/syntastic'

" Plugin 'evidens/vim-twig'
" Plugin 'wakatime/vim-wakatime'

call vundle#end()            " required
filetype plugin indent on    " required

" --- Basic Stuffs --- "
set nobackup
set nowritebackup
set noswapfile
set history=500
set ruler
set showcmd
set incsearch
set ignorecase
set smartcase
set nowrap
set laststatus=2
set backspace=indent,eol,start

" --- Search Ignores --- "
set wildignore+=*.o,*.out,*.obj,.git,*.rbc,*.rbo,*.class,.svn,*.gem
set wildignore+=*.zip,*.tar.gz,*.tar.bz2,*.rar,*.tar.xz
set wildignore+=*/vendor/gems/*,*/vendor/cache/*,*/.bundle/*,*/.sass-cache/*
set wildignore+=*/tmp/cache/assets/*/sprockets/*,*/tmp/cache/assets/*/sass/*
set wildignore+=*.swp,*~,._*

" --- Relative Line Numbers <3 <3 ( ͡° ͜ʖ ͡°) --- "
set relativenumber

" --- Tabs --- "
set tabstop=2
set shiftwidth=2
set expandtab

" --- Show Trailing Whitespace ---"
set list listchars=tab:»·,trail:·

" --- Colour Scheme --- "
syntax enable
set background=dark
colorscheme solarized

" --- Grep outta my god-damn face --- "
set grepprg=ag\ --nogroup\ --nocolor

" --- Ctrl-P = Lightning Speed and awesomness --- "
let g:ctrlp_user_command = 'ag %s -l --nocolor -g ""'
let g:ctrlp_use_caching = 1
let g:ctrlp_max_files = 0
let g:ctrlp_max_depth = 40

" If you could work like a sensible piece of software that'd be great.
function! RestoreRegister()
  let @" = s:restore_reg
  return ''
endfunction

function! s:Repl()
    let s:restore_reg = @"
    return "p@=RestoreRegister()\<cr>"
endfunction

vnoremap <silent> <expr> p <sid>Repl()

" --- Go straight into splits when you make them --- "
set splitbelow
set splitright

" Treat <li> and <p> tags like the block tags they are
let g:html_indent_tags = 'li\|p'

let mapleader="\<Space>"

" Open the current folder in finder
map <Leader>o :!open %:h<CR>

" No highlighting please
set nohlsearch

" Use Ag
let g:ctrlp_use_caching = 0
if executable('ag')
    set grepprg=ag\ --nogroup\ --nocolor

    let g:ctrlp_user_command = 'ag %s -l --nocolor -g ""'
else
  let g:ctrlp_user_command = ['.git', 'cd %s && git ls-files . -co --exclude-standard', 'find %s -type f']
  let g:ctrlp_prompt_mappings = {
    \ 'AcceptSelection("e")': ['<space>', '<cr>', '<2-LeftMouse>'],
    \ }
endif

"" NERDTree
let NERDTreeQuitOnOpen = 1

"" Ctrl-P
set runtimepath^=~/.vim/bundle/ctrlp.vim

" -- Key Mappings and Ting --- "
"
map <Leader>s :Ag -i ''<Left>

nmap <silent> <leader>ev :e $MYVIMRC<cr>
nmap <silent> <leader>sv :so $MYVIMRC<cr>
