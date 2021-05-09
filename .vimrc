"execute pathogen#infect()
syntax on
filetype plugin on
set title
"map leader
"let mapleader = "\<Space>"
set guioptions-=r	"remove right hand scroll bar
set guioptions-=m	"remove menu bar
"nerdtree settings
highlight Directory ctermfg=blue
" for copying without line numbers
set mouse+=a
set rtp+=~/.fzf
let g:NERDTreeDirArrowExpandable = '+'
let g:NERDTreeDirArrowCollapsible = '-'
let NERDTreeHighlightCursorline=0
nmap <F2> :NERDTreeToggle<CR>

" Start interactive EasyAlign in visual mode (e.g. vipga)
xmap ga <Plug>(EasyAlign)

" Start interactive EasyAlign for a motion/text object (e.g. gaip)
nmap ga <Plug>(EasyAlign)

" clipboard functionality pasting and copying
set clipboard=unnamedplus

let g:system_copy#copy_command='xclip -sel clipboard'

inoremap <c-n> <Esc>

"iab { {<CR>}<Esc>ko
"inoremap ( ()<Left>
"inoremap [ []<Left>
"inoremap " ""<Left>
"inoremap ' ''<Left>

call plug#begin('~/.vim/plugged')
"installing plugins
"
Plug 'neelabalan/vim-code-dark'
Plug 'christoomey/vim-system-copy'
Plug 'junegunn/fzf', { 'dir': '~/.fzf', 'do': './install --all' }
Plug 'scrooloose/nerdtree', { 'on':  'NERDTreeToggle' }
Plug 'junegunn/vim-easy-align'
Plug 'Yggdroot/indentLine'
Plug 'preservim/nerdcommenter'
Plug 'plasticboy/vim-markdown'
Plug 'gabrielelana/vim-markdown'
Plug 'dhruvasagar/vim-table-mode'
Plug 'sheerun/vim-polyglot'
Plug 'neelabalan/lightline.vim'
Plug 'vitalk/vim-simple-todo'


call plug#end()

filetype plugin indent on
set lazyredraw
set smartcase
set smartindent
set ignorecase
set nocompatible
set number
set numberwidth=1
set autoindent
set backspace=2
set backspace=indent,eol,start
set shiftwidth=4
set tabstop=4
set softtabstop=4
set expandtab
set shellslash
set clipboard=unnamed
set smarttab

autocmd FileType python set ts=4



set undodir=~/.vimdid
set undofile
" related to vim lightline settings
set laststatus=2
set noshowmode

let g:ycm_python_binary_path = 'python3'
let g:ycm_autoclose_preview_window_after_completion=1
let g:ycm_show_diagnostics_ui = 0
let g:ycm_enable_diagnostic_signs = 0
let g:ycm_enable_diagnostic_highlighting = 0

"let g:indentLine_setColors = 0
let g:indentLine_color_term=239
let g:indentLine_bgcolor_term = 16
let g:indentLine_char_list = ['|']

" tab color
highlight TabLineFill ctermfg=254 ctermbg=238 cterm=none
highlight TabLine ctermfg=254 ctermbg=235 cterm=none
highlight TabLineSel ctermfg=Red ctermbg=Yellow

"status line
let g:lightline = { 'colorscheme':'subtle'}

filetype indent on
nnoremap <C-J> <C-W><C-J>
nnoremap <C-K> <C-W><C-K>
nnoremap <C-L> <C-W><C-L>
nnoremap <C-H> <C-W><C-H>

nnoremap H :tabprevious<CR>
nnoremap L :tabnext<CR>
nnoremap <C-f> :FZF<CR>
nnoremap <C-g> :Rg<CR>
nnoremap <C-b> :Buffers<CR>
"imap ^[OA <ESC>ki
"imap ^[OB <ESC>ji
"imap ^[OC <ESC>li
"imap ^[OD <ESC>hi

function! s:buflist()
  redir => ls
  silent ls
  redir END
  return split(ls, '\n')
endfunction

function! s:bufopen(e)
  execute 'buffer' matchstr(a:e, '^[ 0-9]*')
endfunction
nnoremap <silent> <Leader><Enter> :call fzf#run({
\   'source':  reverse(<sid>buflist()),
\   'sink':    function('<sid>bufopen'),
\   'options': '+m',
\   'down':    len(<sid>buflist()) + 2
\ })<CR>


set colorcolumn=80
au BufNewFile,BufFilePre,BufRead *.md set filetype=markdown

iab xdate <c-r>=strftime("%d-%m-%y %X")<cr>
""""""""""""""""""""""""""""""""""""""""""""""
augroup markdown
    au!
    au BufNewFile,BufRead *.md,*.markdown setlocal filetype=markdown
	autocmd BufNewFile,BufRead,BufWrite *.md syn clear mkdLineBreak
    au FileType markdown setlocal ts=4 sw=4 noet
	"autocmd :syn clear mkdLineBreak
augroup END

" disabled folding in plastic boy markdown
let g:vim_markdown_folding_disabled=1
let g:vim_markdown_conceal=0
let g:vim_markdown_conceal_code_blocks=0


""""""""""""""""""""""""""""""""""""""""""""""
let python_highlight_all = 1

"command R ! gnome-terminal -x bash -c 
""python3 ~/%" 
if has("gui_running")
	colorscheme eldar
	set background=dark
	hi Directory guifg=#7aadff 
endif

let mapleader = ";"
set timeoutlen=300 ttimeoutlen=0


set guifont=Roboto\ Mono\ Regular\ 11
set guioptions-=T "remove toolbar
if !has("gui_running")
	set background=dark
	set t_Co=256
    inoremap <Char-0x07F> <BS>
    nnoremap <Char-0x07F> <BS>
	colorscheme codedark
"    colorscheme myblack
endif
"call feedkeys('<C-[>')
