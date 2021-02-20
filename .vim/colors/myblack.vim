" Dark color scheme

set background=dark
hi clear
if exists("syntax_on")
    syntax reset
endif
let g:colors_name="myblack"

" GUI Color Scheme
hi Normal       cterm=NONE     ctermfg=15	   ctermbg=16
hi NonText      cterm=NONE     ctermfg=244	   ctermbg=16
hi Function     cterm=NONE     ctermfg=74	   ctermbg=16
hi Statement    cterm=NONE 	   ctermfg=202	   ctermbg=16
hi Special      cterm=NONE     ctermfg=14	   ctermbg=16
hi Constant     cterm=NONE     ctermfg=81	   ctermbg=16
hi Comment      cterm=NONE     ctermfg=121	   ctermbg=16
hi Preproc      cterm=NONE     ctermfg=70	   ctermbg=16
hi Type         cterm=NONE     ctermfg=4	   ctermbg=16
hi Identifier   cterm=NONE     ctermfg=14	   ctermbg=16
hi StatusLine   cterm=NONE     ctermfg=15	   ctermbg=58	
hi StatusLineNC cterm=NONE     ctermfg=0	   ctermbg=16
hi Visual       cterm=NONE     ctermfg=255	   ctermbg=238	
hi Search       cterm=NONE     ctermbg=238	   ctermfg=255
hi VertSplit    cterm=NONE     ctermfg=15	   ctermbg=241	
hi Directory    cterm=NONE     ctermfg=10	   ctermbg=16
hi WarningMsg   cterm=NONE     ctermfg=124	   ctermbg=16	
hi Error        cterm=NONE     ctermfg=32	   ctermbg=16	
hi Cursor                      ctermfg=15	   ctermbg=47	
hi LineNr       cterm=NONE     ctermfg=244	   ctermbg=16
hi ColorColumn  cterm=NONE                     ctermbg=235
hi ModeMsg      cterm=NONE     ctermfg=21	   ctermbg=15	
hi Question     cterm=NONE     ctermfg=84	   ctermbg=16
hi Todo 		cterm=BOLD     ctermfg=196     ctermbg=238
hi Title 		cterm=NONE 	   ctermfg=226     ctermbg=16
