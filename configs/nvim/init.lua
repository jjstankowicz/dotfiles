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
vim.opt.numberwidth = 2
vim.opt.relativenumber = false
vim.opt.cursorline = true
vim.opt.cursorlineopt = "number"
vim.opt.diffopt:append { "algorithm:histogram", "linematch:60", "context:8" }
vim.opt.fillchars:remove { "vert", "horiz", "verthoriz" }
vim.opt.title = true
vim.opt.titlelen = 0

-- -- -- -- -- -- -- -- --
-- Plugin specifications
-- -- -- -- -- -- -- -- --

require("lazy").setup {
    require("language_tools").plugins(),
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
        "gmr458/vscode_modern_theme.nvim",
        main = "vscode_modern",
        commit = "22371eeb704bed395262e552248c998ef7f41254",
        lazy = false,
        priority = 1000,
        opts = { cursorline = false, transparent_background = false, nvim_tree_darker = false },
    },
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
            local notify = require "notify"
            local direction = require("notify.stages.util").DIRECTION.BOTTOM_UP
            local stages = require "notify.stages.fade_in_slide_out"(direction)
            notify.setup {
                top_down = false,
                stages = stages,
                on_open = function(window)
                    require("popup_backdrop").prepare(window)
                    vim.api.nvim_set_option_value(
                        "winblend",
                        require("theme").popup_blend,
                        { win = window, scope = "local" }
                    )
                end,
            }
            vim.notify = notify
        end,
    },

    -- Markdown Preview
    {
        "iamcco/markdown-preview.nvim",
        cmd = { "MarkdownPreview", "MarkdownPreviewStop" },
        keys = {
            { "<leader>mv", "<cmd>MarkdownPreview<CR>", desc = "Open Markdown browser preview" },
        },
        build = ":call mkdp#util#install_sync()",
        init = function()
            vim.g.mkdp_filetypes = { "markdown" }
        end,
        config = function(plugin)
            require("markdown_source").setup(plugin.dir)
        end,
        ft = { "markdown" },
    },

    -- Markdown rendering in the editor buffer
    {
        "MeanderingProgrammer/render-markdown.nvim",
        tag = "v8.14.0",
        ft = { "markdown" },
        dependencies = { "nvim-treesitter/nvim-treesitter", "nvim-tree/nvim-web-devicons" },
        keys = {
            { "<leader>mr", "<cmd>RenderMarkdown buf_toggle<CR>", desc = "Toggle Markdown rendering" },
        },
        opts = {
            heading = {
                sign = false,
                icons = { "#", "##", "###", "####", "#####", "######" },
                width = "block",
            },
            code = { sign = false, width = "block" },
            custom_handlers = { latex = { parse = require("markdown_math").parse } },
            latex = {
                enabled = true,
                converter = {
                    vim.fn.expand "~/.local/bin/utftex",
                    vim.fn.expand "~/.local/bin/termtex",
                    "utftex",
                    "termtex",
                },
                inline = true,
                block = true,
            },
        },
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

    require("reading").plugins(),
    -- Open file buffers
    require("buffers").plugin(),
    -- Statusline + icons (GUI/TUI feel)
    {
        "nvim-lualine/lualine.nvim",
        dependencies = { "nvim-tree/nvim-web-devicons" },
        config = function()
            require("lualine").setup {
                options = {
                    theme = function()
                        return require("theme").statusline()
                    end,
                    globalstatus = true,
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
        "folke/which-key.nvim",
        tag = "v3.17.0",
        event = "VeryLazy",
        opts = {
            delay = 250,
            preset = "modern",
            win = { border = "rounded" },
            spec = {
                { "<leader>b", group = "Buffers" },
                { "<leader>f", group = "Find" },
                { "<leader>g", group = "Git" },
                { "<leader>m", group = "Markdown" },
                { "<leader>w", group = "Panes" },
            },
        },
    },
    {
        "folke/noice.nvim",
        event = "VeryLazy",
        dependencies = {
            "MunifTanjim/nui.nvim",
            "rcarriga/nvim-notify",
        },
        config = function()
            -- A painted cursor can remain opaque inside a transparent popup.
            require("noice.ui.cmdline").real_cursor = false
            require("noice").setup {
                presets = {
                    command_palette = false, -- turn this OFF so it stops overriding position
                    lsp_doc_border = true, -- enables nice hover windows
                },
                views = {
                    cmdline_popup = {
                        win_options = { winblend = require("theme").popup_blend },
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
                            winblend = require("theme").popup_blend,
                            winhighlight = "Normal:NormalFloat,FloatBorder:FloatBorder",
                        },
                        backend = "popup",
                    },
                    mini = { win_options = { winblend = require("theme").popup_blend } },
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
    require("workspace").plugins(),
    require("git_review").plugins(),
}

require("language_tools").setup()

-- -- -- -- --
-- KEYBINDINGS
-- -- -- -- --

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
vim.keymap.set("n", "<leader>fs", require("telescope.builtin").lsp_document_symbols, { desc = "Find document symbols" })
vim.keymap.set("n", "<leader>fd", require("telescope.builtin").lsp_definitions, { desc = "Find definitions" })
vim.keymap.set("n", "<leader>fr", require("telescope.builtin").lsp_references, { desc = "Find references" })
vim.keymap.set("n", "<leader>fi", require("telescope.builtin").lsp_implementations, { desc = "Find implementations" })
vim.keymap.set("n", "<leader>ff", require("telescope.builtin").find_files, { desc = "Find files" })
vim.keymap.set("n", "<leader>fg", require("telescope.builtin").live_grep, { desc = "Search project text" })
vim.keymap.set("n", "<leader>fb", require("telescope.builtin").buffers, { desc = "Find open buffers" })
vim.keymap.set("n", "<leader>fh", require("telescope.builtin").help_tags, { desc = "Find help" })

-- Word and paragraph navigation
vim.keymap.set({ "n", "x" }, "<leader><Left>", "ge", { desc = "Previous word end" })
vim.keymap.set({ "n", "x" }, "<leader><Right>", "e", { desc = "Next word end" })
vim.keymap.set({ "n", "x" }, "<leader><Up>", "{", { desc = "Previous blank line" })
vim.keymap.set({ "n", "x" }, "<leader><Down>", "}", { desc = "Next blank line" })

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
vim.keymap.set("n", "<leader>v", "<C-Q>", { noremap = true, desc = "Select block" })

require("git_review").setup()
require("theme").setup()
require("popup_backdrop").setup()
require("workspace").setup()
