set number
set hlsearch
set cursorline

set smartindent
set smarttab
set expandtab
set tabstop=4

set clipboard=unnamedplus

call plug#begin('~/.vim/plugged')
Plug 'Raimondi/delimitMate'
Plug 'vim-airline/vim-airline'
Plug 'vim-airline/vim-airline-themes'
Plug 'scrooloose/nerdtree'
Plug 'ryanoasis/vim-devicons'
if empty($VSCODE_NLS_CONFIG)
    Plug 'fatih/vim-go', { 'do': ':GoUpdateBinaries' }
endif
Plug 'junegunn/vim-peekaboo'
Plug 'nvim-tree/nvim-web-devicons' " optional, for file icons
Plug 'nvim-tree/nvim-tree.lua'
Plug 'preservim/tagbar'
Plug 'easymotion/vim-easymotion'
call plug#end()

