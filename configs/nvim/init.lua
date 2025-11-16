-- -- -- -- -- -- -- -- -- -- -- --
-- Lazy initialization of plugins
-- -- -- -- -- -- -- -- -- -- -- --

-- Init.lua
local lazypath = vim.fn.stdpath "data" .. "/lazy/lazy.nvim"
if not vim.loop.fs_stat(lazypath) then
    vim.fn.system {
        "git",
        "clone",
        "--filter=blob:none",
        "https://github.com/folke/lazy.nvim.git",
        "--branch=stable",
        lazypath,
    }
end
vim.opt.rtp:prepend(lazypath)

-- -- -- -- -- -- --
-- Basic vim options
-- -- -- -- -- -- --
vim.g.mapleader = " "
vim.opt.signcolumn = "yes"
vim.opt.number = true -- absolute line numbers
vim.opt.relativenumber = true -- optional: relative numbers

-- -- -- -- -- -- -- -- --
-- Plugin specifications
-- -- -- -- -- -- -- -- --

require("lazy").setup {
    -- LSP Support
    {
        "neovim/nvim-lspconfig",
        dependencies = {
            "hrsh7th/cmp-nvim-lsp",
        },
    },

    -- Autocompletion
    {
        "hrsh7th/nvim-cmp",
        dependencies = {
            "L3MON4D3/LuaSnip",
            "hrsh7th/cmp-buffer",
            "hrsh7th/cmp-path",
            "hrsh7th/cmp-cmdline",
        },
    },

    -- Commenting support
    {
        "numToStr/Comment.nvim",
        config = true,
    },

    -- GitHub Copilot
    "github/copilot.vim",

    -- Terraform support
    {
        "hashivim/vim-terraform",
        dependencies = {
            "hashicorp/terraform-ls",
        },
    },
    -- Color schemes
    {
        "sainnhe/everforest",
        lazy = false,
        priority = 1000,
    },
    {
        "sainnhe/edge",
        lazy = false,
        priority = 1000,
    },
    {
        "rebelot/kanagawa.nvim",
        lazy = false,
        priority = 1000,
    },
    {
        "folke/tokyonight.nvim",
        lazy = false,
        priority = 999,
    },
    {
        "catppuccin/nvim",
        name = "catppuccin",
        priority = 900,
    },
    -- Treesitter
    {
        "nvim-treesitter/nvim-treesitter",
        build = ":TSUpdate",
    },

    -- Debugging
    {
        "mfussenegger/nvim-dap",
        dependencies = {
            "rcarriga/nvim-dap-ui",
            "nvim-neotest/nvim-nio",
        },
    },

    -- Formatting and linting
    {
        "nvimtools/none-ls.nvim",
        dependencies = {
            "nvim-lua/plenary.nvim",
        },
    },

    -- Telescope
    {
        "nvim-telescope/telescope.nvim",
        dependencies = {
            "nvim-lua/plenary.nvim",
        },
    },
    -- Notification manager
    {
        "rcarriga/nvim-notify",
        config = function()
            vim.notify = require "notify"
        end,
    },

    -- Mason (add this before the closing bracket)
    {
        "williamboman/mason.nvim",
        dependencies = {
            "williamboman/mason-lspconfig.nvim",
        },
        config = function()
            require("mason").setup()
            require("mason-lspconfig").setup {
                ensure_installed = { "pyright" },
            }
        end,
    },

    -- Markdown Preview
    {
        "iamcco/markdown-preview.nvim",
        cmd = { "MarkdownPreview", "MarkdownPreviewStop" },
        build = "cd app && npm install",
        init = function()
            vim.g.mkdp_filetypes = { "markdown" }
        end,
        ft = { "markdown" },
    },

    -- Clipboard support over SSH
    {
        "ojroques/nvim-osc52",
        config = function()
            require("osc52").setup {
                max_length = 0,
                silent = false,
                trim = false,
            }
        end,
    },

    -- Indent Blankline
    {
        "lukas-reineke/indent-blankline.nvim",
        main = "ibl", -- For version 3, specify the main module as "ibl"
        config = function()
            require("ibl").setup {
                indent = { char = "┊" }, -- Customize the character
                scope = {
                    enabled = true, -- Enable context highlighting
                    show_start = true, -- Highlight the start of the scope
                    show_end = false, -- Optionally highlight the end of the scope
                },
            }
        end,
    },
    -- Statusline + icons (GUI/TUI feel)
    {
        "nvim-lualine/lualine.nvim",
        dependencies = { "nvim-tree/nvim-web-devicons" },
        config = function()
            require("lualine").setup {
                options = {
                    theme = "auto",
                    icons_enabled = true,
                    component_separators = { left = "", right = "" },
                    section_separators = { left = "", right = "" },
                },
                sections = {
                    lualine_a = { "mode" },
                    lualine_b = { "branch", "diff", "diagnostics" },
                    lualine_c = { "filename" },
                    lualine_x = { "encoding", "fileformat", "filetype" },
                    lualine_y = { "progress" },
                    lualine_z = { "location", { "datetime", style = "%H:%M" } },
                },
            }
        end,
    },
    {
        "folke/noice.nvim",
        event = "VeryLazy",
        dependencies = {
            "MunifTanjim/nui.nvim",
            "rcarriga/nvim-notify",
        },
        config = function()
            require("noice").setup {
                presets = {
                    command_palette = false, -- turn this OFF so it stops overriding position
                    lsp_doc_border = true, -- enables nice hover windows
                },
                views = {
                    cmdline_popup = {
                        position = {
                            row = "50%", -- move it vertically (0% = top, 100% = bottom)
                            col = "50%", -- usually leave centered horizontally
                        },
                        size = {
                            width = 60,
                            height = "auto",
                        },
                    },
                    hover = {
                        border = {
                            style = "rounded",
                        },
                        size = {
                            max_width = 80,
                            max_height = 30,
                        },
                        win_options = {
                            winhighlight = "Normal:NormalFloat,FloatBorder:FloatBorder",
                        },
                        backend = "popup",
                    },
                },
            }
        end,
    },
    -- Improve LSP loading UI
    {
        "j-hui/fidget.nvim",
        tag = "legacy",
        config = function()
            require("fidget").setup {}
        end,
    },
    -- File Explorer
    {
        "nvim-tree/nvim-tree.lua",
        dependencies = { "nvim-tree/nvim-web-devicons" },
        config = function()
            require("nvim-tree").setup {
                filters = { dotfiles = true },
                view = { width = 30, side = "left" },
                git = { enable = true },
            }

            -- <leader>x to toggle the file tree
            vim.keymap.set("n", "<leader>x", "<cmd>NvimTreeToggle<CR>", { noremap = true, silent = true })
        end,
    },
    -- Floating terminal
    {
        "akinsho/toggleterm.nvim",
        version = "*",
        config = function()
            require("toggleterm").setup {
                size = function(term)
                    if term.direction == "horizontal" then
                        return 15
                    elseif term.direction == "vertical" then
                        return vim.o.columns * 0.4
                    end
                end,
                open_mapping = [[<c-\>]],
                direction = "horizontal",
                float_opts = { border = "single" },
            }
        end,
    },
}

-- Autocompletion setup
local cmp = require "cmp"
local luasnip = require "luasnip"

cmp.setup {
    snippet = {
        expand = function(args)
            luasnip.lsp_expand(args.body)
        end,
    },
    mapping = cmp.mapping.preset.insert {
        ["<C-b>"] = cmp.mapping.scroll_docs(-4),
        ["<C-f>"] = cmp.mapping.scroll_docs(4),
        ["<C-Space>"] = cmp.mapping.complete(),
        ["<C-e>"] = cmp.mapping.abort(),
        ["<CR>"] = cmp.mapping.confirm { select = true },
        ["<C-Tab>"] = cmp.mapping(function(fallback)
            if cmp.visible() then
                cmp.select_next_item()
            elseif luasnip.expand_or_jumpable() then
                luasnip.expand_or_jump()
            else
                fallback()
            end
        end, { "i", "s" }),
        ["<C-S-Tab>"] = cmp.mapping(function(fallback)
            if cmp.visible() then
                cmp.select_prev_item()
            elseif luasnip.jumpable(-1) then
                luasnip.jump(-1)
            else
                fallback()
            end
        end, { "i", "s" }),
    },
    sources = cmp.config.sources({
        { name = "nvim_lsp" },
        { name = "luasnip" },
    }, {
        { name = "buffer" },
        { name = "path" },
    }),
}

-- LSP + Linting Setup
vim.diagnostic.config {
    virtual_text = { -- Keep diagnostics visible inline
        spacing = 4,
        source = "always", -- Show where the diagnostic comes from (LSP/null-ls)
    },
    signs = true, -- Show diagnostic signs in the sign column
    underline = true, -- Underline problematic code
    update_in_insert = false, -- Don't show diagnostics while typing
    severity_sort = true, -- Sort diagnostics by severity
    float = { border = "rounded", source = "always" }, -- Show source in hover
}

-- LSP capabilities for completion, applied to all servers
local capabilities = require("cmp_nvim_lsp").default_capabilities()

vim.lsp.config("*", {
    capabilities = capabilities,
})

-- Pyright configuration using the new vim.lsp.config API
vim.lsp.config("pyright", {
    settings = {
        python = {
            analysis = {
                typeCheckingMode = "basic",
                diagnosticMode = "workspace",
                diagnosticSeverityOverrides = {
                    reportGeneralTypeIssues = "error",
                    reportShadowedImports = "error",
                },
            },
        },
    },
    root_dir = function(fname)
        local util = require "lspconfig.util"
        return util.find_git_ancestor(fname) or util.path.dirname(fname)
    end,
    before_init = function(_, config)
        config.init_options = {
            maxProjectFiles = 10000,
            maxListeners = 20,
        }
    end,
})

-- Enable Pyright (auto-start based on filetype/root)
vim.lsp.enable "pyright"

-- Rust Analyzer (same API as pyright)
vim.lsp.config("rust_analyzer", {
    capabilities = capabilities,
})
vim.lsp.enable "rust_analyzer"

-- Setup null-ls
local null_ls = require "null-ls"
local augroup = vim.api.nvim_create_augroup("LspFormatting", {}) -- Add this line
null_ls.setup {
    sources = {
        null_ls.builtins.diagnostics.pylint,
        -- null_ls.builtins.diagnostics.ruff.with({
        --     extra_args = { "--max-line-length", "100" },
        -- }),
        null_ls.builtins.formatting.black.with {
            extra_args = { "--line-length", "100" },
        },
        null_ls.builtins.formatting.stylua.with {
            extra_args = { "--config-path", vim.fn.expand "~/.config/nvim/stylua.toml" },
        },
    },
    on_attach = function(client, bufnr)
        -- Enable formatting on save
        if client.supports_method "textDocument/formatting" then
            vim.api.nvim_clear_autocmds { group = augroup, buffer = bufnr }
            vim.api.nvim_create_autocmd("BufWritePre", {
                group = augroup,
                buffer = bufnr,
                callback = function()
                    vim.lsp.buf.format {
                        bufnr = bufnr,
                        timeout_ms = 5000,
                    }
                end,
            })
        end
    end,
}

-- -- -- -- --
-- KEYBINDINGS
-- -- -- -- --

-- LSP keymaps
vim.keymap.set("n", "gd", vim.lsp.buf.definition)
vim.keymap.set("n", "K", vim.lsp.buf.hover)

-- Hover keymaps
vim.keymap.set("n", "<leader>e", function()
    vim.diagnostic.open_float(nil, { focusable = true, scope = "cursor" })
end, { noremap = true, silent = true })

-- Telescope keymaps
require("telescope").setup {
    defaults = {
        file_ignore_patterns = { "node_modules", ".git" },
        vimgrep_arguments = {
            "rg",
            "--color=never",
            "--no-heading",
            "--with-filename",
            "--line-number",
            "--column",
            "--smart-case",
            "--hidden",
        },
        mappings = {
            i = {
                ["<C-h>"] = "which_key",
            },
        },
    },
    pickers = {
        find_files = {
            find_command = { "rg", "--files", "--hidden", "--glob", "!**/.git/*" },
        },
        lsp_definitions = {
            jump_type = "never", -- This prevents automatic jumping
        },
    },
}
vim.keymap.set("n", "<leader>fs", require("telescope.builtin").lsp_document_symbols)
vim.keymap.set("n", "<leader>fd", require("telescope.builtin").lsp_definitions)
vim.keymap.set("n", "<leader>fr", require("telescope.builtin").lsp_references)
vim.keymap.set("n", "<leader>fi", require("telescope.builtin").lsp_implementations)
vim.keymap.set("n", "gs", vim.lsp.buf.signature_help) -- Quick signature view without Telescope
vim.keymap.set("n", "<leader>ff", require("telescope.builtin").find_files)
vim.keymap.set("n", "<leader>fg", require("telescope.builtin").live_grep)
vim.keymap.set("n", "<leader>fb", require("telescope.builtin").buffers)
vim.keymap.set("n", "<leader>fh", require("telescope.builtin").help_tags)

-- Comment keymaps
vim.keymap.set("n", "<C-_>", function()
    require("Comment.api").toggle.linewise.current()
end)
vim.keymap.set("v", "<C-_>", function()
    require("Comment.api").toggle.linewise(vim.fn.visualmode())
end)

-- Command mode navigation
vim.keymap.set("c", "<Up>", function()
    return vim.fn.wildmenumode() == 1 and "<C-p>" or "<Up>"
end, { expr = true })
vim.keymap.set("c", "<Down>", function()
    return vim.fn.wildmenumode() == 1 and "<C-n>" or "<Down>"
end, { expr = true })

-- Clipboard

-- Clipboard: smart detection for WSL vs remote
local function is_wsl()
    local output = vim.fn.systemlist "uname -r"
    return output[1] and output[1]:lower():match "microsoft" and true or false
end

if is_wsl() then
    -- Use clip.exe in WSL
    vim.keymap.set("x", "cc", ":w !clip.exe<CR>")
else
    -- Use osc52 for remote machines
    vim.keymap.set("x", "cc", require("osc52").copy_visual)
    -- Set up clipboard provider for mouse selection
    local function copy(lines, _)
        require("osc52").copy(table.concat(lines, "\n"))
        return 0
    end

    local function paste()
        return { vim.fn.split(vim.fn.getreg "", "\n"), vim.fn.getregtype "" }
    end

    vim.g.clipboard = {
        name = "osc52",
        copy = { ["+"] = copy, ["*"] = copy },
        paste = { ["+"] = paste, ["*"] = paste },
    }
end

-- Block select
vim.keymap.set("n", "<leader>v", "<C-Q>", { noremap = true })

-- -- -- -- -- --
-- CONFIGURATION
-- -- -- -- -- --

-- Format on save for Python files
vim.api.nvim_create_autocmd("BufWritePre", {
    pattern = "*.py",
    callback = function()
        vim.lsp.buf.format { async = false }
    end,
})

-- Set colorscheme
vim.opt.termguicolors = true
vim.o.background = "dark"
vim.cmd.colorscheme "tokyonight-night"

vim.api.nvim_set_hl(0, "NormalFloat", { bg = "none" })
vim.opt.winblend = 10
