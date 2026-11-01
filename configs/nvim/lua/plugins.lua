---Plugin specifications shared by interactive startup and the installer.
return {
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
