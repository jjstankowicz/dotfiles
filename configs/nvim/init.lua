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

require("lazy").setup(require "plugins")

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
