local M = {}

local function setup_scrollbars(options)
    local scrollview = require "scrollview"
    scrollview.setup(options)
    local paused = false
    local scheduled = false
    local function restore()
        scheduled = false
        if not paused then
            return
        end
        for _, window in ipairs(vim.api.nvim_tabpage_list_wins(0)) do
            if vim.bo[vim.api.nvim_win_get_buf(window)].filetype == "TelescopePrompt" then
                return
            end
        end
        paused = false
        scrollview.set_state(true)
    end
    local function schedule_restore()
        if paused and not scheduled then
            scheduled = true
            vim.schedule(restore)
        end
    end
    local group = vim.api.nvim_create_augroup("ReadingPickerScrollbars", { clear = true })
    vim.api.nvim_create_autocmd("User", {
        group = group,
        pattern = "TelescopeFindPre",
        callback = function()
            if vim.g.scrollview_enabled then
                paused = true
                scrollview.set_state(false)
                schedule_restore()
            end
        end,
    })
    vim.api.nvim_create_autocmd({ "BufEnter", "WinEnter", "WinClosed" }, {
        group = group,
        callback = schedule_restore,
    })
end

---Return plugins that add context and navigation cues without changing the pane layout.
function M.plugins()
    return {
        {
            "stevearc/aerial.nvim",
            branch = "nvim-0.11",
            commit = "c5e56945d9703f7079ccff484b35d0e4c231dd6c",
            dependencies = { "nvim-treesitter/nvim-treesitter", "nvim-tree/nvim-web-devicons" },
            opts = function()
                return require("code_outline").options()
            end,
            config = function(_, options)
                require("code_outline").setup(options)
            end,
        },
        {
            "nvim-treesitter/nvim-treesitter",
            opts = {
                ensure_installed = { "python", "lua", "markdown", "markdown_inline", "latex", "bash", "json" },
                highlight = { enable = true },
            },
            config = function(_, options)
                require("nvim-treesitter.configs").setup(options)
            end,
        },
        {
            "nvim-treesitter/nvim-treesitter-context",
            commit = "8decd73460d26ef0a0befb745d022dd1fc2c38b8",
            dependencies = { "nvim-treesitter/nvim-treesitter" },
            opts = {
                max_lines = 2,
                multiline_threshold = 1,
                min_window_height = 12,
                multiwindow = true,
                zindex = 25,
                on_attach = function(buffer)
                    return vim.bo[buffer].buftype == ""
                end,
            },
        },
        {
            "lukas-reineke/indent-blankline.nvim",
            main = "ibl",
            config = function(_, options)
                local hooks = require "ibl.hooks"
                hooks.register(hooks.type.HIGHLIGHT_SETUP, require("theme").reading_highlights)
                require("ibl").setup(options)
            end,
            opts = {
                indent = { char = vim.fn.nr2char(0x2502), highlight = "ReadingIndent" },
                scope = {
                    enabled = true,
                    char = vim.fn.nr2char(0x2502),
                    highlight = "ReadingScope",
                    show_start = false,
                    show_end = false,
                },
            },
        },
        {
            "dstein64/nvim-scrollview",
            commit = "b9e6ee00e9e20330b426fbec47812c2213d371ca",
            config = function(_, options)
                setup_scrollbars(options)
            end,
            opts = {
                floating_windows = true,
                character = vim.fn.nr2char(0x2595),
                current_only = false,
                visibility = "overflow",
                base = "right",
                column = 1,
                consider_border = false,
                zindex = 30,
                winblend = 0,
                winblend_gui = 0,
                excluded_filetypes = {
                    "framed-header",
                    "notify",
                    "noice",
                    "lazy",
                    "TelescopePrompt",
                    "TelescopeResults",
                    "cmp_menu",
                    "cmp_docs",
                    "WhichKey",
                },
                signs_on_startup = { "diagnostics", "search" },
                diagnostics_severities = { vim.diagnostic.severity.ERROR, vim.diagnostic.severity.WARN },
            },
        },
    }
end

return M
