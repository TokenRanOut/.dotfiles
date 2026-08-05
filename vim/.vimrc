call plug#begin()

let g:plug_url_format = 'git@github.com:%s.git'

Plug 'prabirshrestha/vim-lsp'
Plug 'mattn/vim-lsp-settings'
Plug 'prabirshrestha/asyncomplete.vim'
Plug 'prabirshrestha/asyncomplete-lsp.vim'
Plug 'jiangmiao/auto-pairs'
Plug 'tomasiser/vim-code-dark'
Plug 'preservim/nerdtree'
Plug 'vim-airline/vim-airline'
Plug 'hrsh7th/vim-vsnip'
Plug 'hrsh7th/vim-vsnip-integ'
Plug 'rafamadriz/friendly-snippets'

call plug#end()

let g:lsp_settings = {
\   'pylsp-all': {
\     'workspace_config': {
\       'pylsp': {
\         'configurationSources': ['flake8']
\       }
\     }
\   },
\}

function! s:on_lsp_buffer_enabled() abort
    setlocal omnifunc=lsp#complete
    setlocal signcolumn=yes
    if exists('+tagfunc') | setlocal tagfunc=lsp#tagfunc | endif
    nmap <buffer> gd <plug>(lsp-definition)
    nmap <buffer> gs <plug>(lsp-document-symbol-search)
    nmap <buffer> gS <plug>(lsp-workspace-symbol-search)
    nmap <buffer> gr <plug>(lsp-references)
    nmap <buffer> gi <plug>(lsp-implementation)
    nmap <buffer> gt <plug>(lsp-type-definition)
    nmap <buffer> <leader>rn <plug>(lsp-rename)
    nmap <buffer> [g <plug>(lsp-previous-diagnostic)
    nmap <buffer> ]g <plug>(lsp-next-diagnostic)
    nmap <buffer> K <plug>(lsp-hover)
    nnoremap <buffer> <expr><c-f> lsp#scroll(+4)
    nnoremap <buffer> <expr><c-d> lsp#scroll(-4)

    let g:lsp_format_sync_timeout = 1000
    autocmd! BufWritePre *.rs,*.go,*.py,*.java call execute('LspDocumentFormatSync')
    
    " refer to doc to add more commands
endfunction

augroup lsp_install
    au!
    " call s:on_lsp_buffer_enabled only for languages that has the server registered.
    autocmd User lsp_buffer_enabled call s:on_lsp_buffer_enabled()
augroup END


augroup autosave
    autocmd!
    autocmd CursorHold,CursorHoldI,InsertLeave * update
augroup END

augroup remove_tail_space
    autocmd!
    autocmd BufWritePre * if &filetype !~# 'markdown\|diff' | %s/\s\+$//e | endif
augroup END

inoremap <expr> <Tab>   pumvisible() ? "\<C-n>" : "\<Tab>"
inoremap <expr> <S-Tab> pumvisible() ? "\<C-p>" : "\<S-Tab>"
inoremap <expr> <cr>    pumvisible() ? asyncomplete#close_popup() : "\<cr>"


set nocompatible
set showmode
set showcmd
set mouse=a
set encoding=utf-8
set t_Co=256
set autoindent
set tabstop=2
set shiftwidth=2
set expandtab
set softtabstop=2
set number
set relativenumber
set cursorline
set cursorcolumn
set scrolloff=5
set laststatus=2
set ruler
set showmatch
set hlsearch
set spell spelllang=en_us
set backupdir=~/.vim/.backup//
set directory=~/.vim/.swp//
set undodir=~/.vim/.undo//
set autochdir
set noerrorbells
set history=1000
set autoread
set listchars=tab:»■,trail:■
set list
set wildmenu
set wildmode=longest:list,full
set timeoutlen=3000

filetype indent on
syntax on

colorscheme codedark
