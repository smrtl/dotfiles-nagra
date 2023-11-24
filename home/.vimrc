" Plugin system
call plug#begin('~/.vim/plugged')
 
Plug 'vim-scripts/0x7A69_dark.vim'
" Plug 'neoclide/coc.nvim', {'branch': 'release'}
" Plug 'neoclide/coc-python'
 
call plug#end()
 
" Custom settings
filetype plugin indent on
set tabstop=2
set shiftwidth=2
set expandtab
syntax on
