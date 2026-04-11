"" keymaps
let mapleader = " "
nnoremap <silent> <C-a> ggVG
nnoremap <silent> <Esc> :nohlsearch<CR>

"" plugins
call plug#begin()
Plug 'tpope/vim-sensible'
Plug 'tpope/vim-fugitive'
Plug 'tpope/vim-surround'
Plug 'tpope/vim-commentary'
Plug 'matze/vim-move'
Plug 'scrooloose/nerdtree'
Plug 'christoomey/vim-tmux-navigator'
Plug 'rose-pine/vim'
call plug#end()

"" settings
set number
set tabstop=2
set shiftwidth=2
"set signcolumn=yes
set scrolloff=5
"set noshowmode
set clipboard=unnamedplus
set ignorecase
set smartcase
set hlsearch
set incsearch
set nobackup
set termguicolors
set cursorline
set background=dark
colorscheme rosepine

"" plugins' settings
" nerdtree
let g:NERDTreeFileLines = 1
nnoremap <leader>w :NERDTreeToggle<CR>
nnoremap <C-f> :NERDTreeFind<CR>
autocmd BufEnter * if winnr() == winnr('h') && bufname('#') =~ 'NERD_tree_\d\+' && bufname('%') !~ 'NERD_tree_\d\+' && winnr('$') > 1 |
    \ let buf=bufnr() | buffer# | execute "normal! \<C-W>w" | execute 'buffer'.buf | endif
" vim-surround
let g:surround_no_mappings = 1
nmap sa <Plug>Ysurround
xmap sa <Plug>VSurround
nmap sd <Plug>Dsurround
nmap sr <Plug>Csurround
" vim-move
nnoremap <A-C-Up> :m .-2<CR>==
nnoremap <A-C-Down> :m .+1<CR>==
nnoremap <A-C-Left> <<
nnoremap <A-C-Right> >>
vnoremap <A-C-Up> :m '<-2<CR>gv=gv
vnoremap <A-C-Down> :m '>+1<CR>gv=gv
vnoremap <A-C-Left> <gv
vnoremap <A-C-Right> >gv
" vim-commentary
autocmd FileType vimrc setlocal commentstring="
" vim-bufferline
nmap <Tab> bnext
nmap <S-Tab> bprevious
" vim-tmux-navigator
let g:tmux_navigator_no_mappings = 1
nnoremap <silent> <C-Left> :TmuxNavigateLeft<cr>
nnoremap <silent> <C-Right> :TmuxNavigateDown<cr>
nnoremap <silent> <C-Up> :TmuxNavigateUp<cr>
nnoremap <silent> <C-Right> :TmuxNavigateRight<cr>
