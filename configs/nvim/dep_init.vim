" Load original vimrc
set runtimepath^=~/.vim runtimepath+=~/.vim/after
let &packpath = &runtimepath
source ~/.vimrc

" Navigate with up/down arrows
cnoremap <expr> <Up> wildmenumode() ? "\<C-p>" : "\<Up>"
cnoremap <expr> <Down> wildmenumode() ? "\<C-n>" : "\<Down>"

" Set leader key
let mapleader = " "

" Set colorscheme
set background=light

" Set up plugins
call plug#begin('~/.vim/plugged')

" Add this plugin for commenting
Plug 'numToStr/Comment.nvim'

" Add GitHub Copilot plugin
Plug 'github/copilot.vim'

" Add LSP plugin
Plug 'neovim/nvim-lspconfig'

" Add terraform LSP
Plug 'hashicorp/terraform-ls'

" Add terraform commenting
Plug 'hashivim/vim-terraform'

" Nice colorscheme 
Plug 'catppuccin/nvim', { 'as': 'catppuccin' }

" Treesitter does syntax highlighting
Plug 'nvim-treesitter/nvim-treesitter', {'do': ':TSUpdate'}

" nvim-cmp core plugin
Plug 'hrsh7th/nvim-cmp'

" nvim-cmp completion sources
Plug 'hrsh7th/cmp-nvim-lsp'
Plug 'hrsh7th/cmp-buffer'
Plug 'hrsh7th/cmp-path'
Plug 'hrsh7th/cmp-cmdline'

" Snippet engine (required by nvim-cmp)
Plug 'L3MON4D3/LuaSnip'

" Install nvim-dap and nvim-dap-ui
Plug 'nvim-neotest/nvim-nio'
Plug 'mfussenegger/nvim-dap'
Plug 'rcarriga/nvim-dap-ui'

" Install linting/formatting tools 
Plug 'nvim-lua/plenary.nvim' " Dependency
Plug 'jose-elias-alvarez/null-ls.nvim'

" Install telescope
Plug 'nvim-lua/plenary.nvim'
Plug 'nvim-telescope/telescope.nvim'

call plug#end()

" Toggle comments in normal and visual modes using <C-/>
nnoremap <C-_> :lua require('Comment.api').toggle.linewise.current()<CR>
vnoremap <C-_> :lua require('Comment.api').toggle.linewise(vim.fn.visualmode())<CR>


nnoremap <silent> gd <cmd>lua vim.lsp.buf.definition()<CR>
nnoremap <silent> K <cmd>lua vim.lsp.buf.hover()<CR>

lua require("config")
" lua << EOF
" require('lspconfig').pyright.setup{}
" EOF

colorscheme catppuccin-latte 

xnoremap cc :w !clip.exe<CR>

set signcolumn=yes

" autocmd InsertLeave *.py lua vim.lsp.buf.format({ async = false })
autocmd BufWritePre *.py lua vim.lsp.buf.format({ async = false })

" Telescope setup
nnoremap <leader>ff :Telescope find_files<CR>
nnoremap <leader>fg :Telescope live_grep<CR>
nnoremap <leader>fb :Telescope buffers<CR>
nnoremap <leader>fh :Telescope help_tags<CR>
