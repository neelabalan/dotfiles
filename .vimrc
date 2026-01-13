" basic settings
set nocompatible
syntax on
filetype plugin indent on

" ui
set number
set numberwidth=1
set ruler
set laststatus=2
set showmode
set showcmd
set title
set background=dark
set t_Co=256

" editing
set backspace=indent,eol,start
set autoindent
set smartindent
set tabstop=4
set shiftwidth=4
set softtabstop=4
set expandtab
set smarttab

" search
set incsearch
set hlsearch
set ignorecase
set smartcase

" performance
set lazyredraw
set ttyfast

" usability
set mouse=a
set clipboard=unnamedplus
set hidden
set wildmenu
set wildmode=list:longest
set scrolloff=5
set splitbelow
set splitright

" persistent undo
set undofile
set undodir=~/.vim/undo
if !isdirectory(&undodir)
    call mkdir(&undodir, 'p')
endif

" disable backups and swap (optional, comment out if you want them)
set nobackup
set nowritebackup
set noswapfile

" leader key
let mapleader = ";"
set timeoutlen=300 ttimeoutlen=0

" window navigation
nnoremap <C-h> <C-w>h
nnoremap <C-j> <C-w>j
nnoremap <C-k> <C-w>k
nnoremap <C-l> <C-w>l

" tab navigation
nnoremap ( :tabprevious<CR>
nnoremap ) :tabnext<CR>

" quick save
nnoremap <leader>w :w<CR>

" clear search highlight
nnoremap <leader><space> :nohlsearch<CR>

" date abbreviations
iab xdate <c-r>=strftime("%d-%m-%y %X")<cr>
iab xxdate <c-r>=strftime("%a, %d %b %Y")<cr>

" netrw file browser (built-in)
let g:netrw_banner = 0
let g:netrw_liststyle = 3
let g:netrw_winsize = 25
nnoremap <F2> :Lexplore<CR>
