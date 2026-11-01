local M = {}

---Return commit comparison, diff scrolling, and Git terminal specifications.
function M.plugins()
    return {
        -- Commit comparisons
        {
            "sindrets/diffview.nvim",
            commit = "4516612fe98ff56ae0415a259ff6361a89419b0a",
            cmd = { "DiffviewOpen", "DiffviewClose", "DiffviewFileHistory", "DiffviewRefresh" },
            dependencies = { "nvim-lua/plenary.nvim", "nvim-tree/nvim-web-devicons" },
            keys = {
                {
                    "<leader>gd",
                    function()
                        local directory = vim.fn.getcwd()
                        local file = vim.api.nvim_buf_get_name(0)
                        if vim.bo.buftype == "" and file ~= "" then
                            directory = vim.fn.isdirectory(file) == 1 and file or vim.fn.fnamemodify(file, ":h")
                        end
                        local roots = vim.fn.systemlist { "git", "-C", directory, "rev-parse", "--show-toplevel" }
                        if vim.v.shell_error ~= 0 then
                            vim.notify("Open a file or directory in a Git repository", vim.log.levels.WARN)
                            return
                        end
                        local root = roots[1]
                        require("telescope.builtin").git_commits {
                            cwd = root,
                            prompt_title = "Compare commit with working tree",
                            attach_mappings = function(prompt, map)
                                local actions = require "telescope.actions"
                                actions.select_default:replace(function()
                                    local entry = require("telescope.actions.state").get_selected_entry()
                                    if not entry then
                                        return
                                    end
                                    actions.close(prompt)
                                    vim.cmd.DiffviewOpen { args = { entry.value, "-C" .. root } }
                                end)
                                for _, key in ipairs { "<C-r>m", "<C-r>s", "<C-r>h" } do
                                    map({ "i", "n" }, key, false)
                                end
                                return true
                            end,
                        }
                    end,
                    desc = "Compare commit with working tree",
                },
                {
                    "<leader>gD",
                    "<cmd>DiffviewOpen main<CR>",
                    desc = "Compare main with working tree",
                },
            },
            opts = {
                view = {
                    default = { layout = "diff2_horizontal", winbar_info = true },
                },
                file_panel = { win_config = { position = "left", width = 30 } },
                hooks = {
                    diff_buf_win_enter = function(buffer, window)
                        vim.wo[window].scrollbind = true
                        vim.wo[window].cursorbind = true
                        vim.wo[window].foldenable = false
                        vim.wo[window].wrap = false
                        for _, key in ipairs { "<ScrollWheelUp>", "<ScrollWheelDown>" } do
                            vim.keymap.set({ "n", "x", "i" }, key, function()
                                local target = vim.fn.getmousepos().winid
                                if vim.api.nvim_win_is_valid(target) and vim.wo[target].diff then
                                    vim.api.nvim_set_current_win(target)
                                    local count = tonumber(vim.o.mousescroll:match "ver:(%d+)") or 3
                                    if count == 0 then
                                        return
                                    end
                                    local command = key == "<ScrollWheelDown>" and "<C-e>" or "<C-y>"
                                    local input = vim.api.nvim_replace_termcodes(command, true, false, true)
                                    local prefix = ""
                                    if vim.api.nvim_get_mode().mode:sub(1, 1) == "i" then
                                        prefix = vim.api.nvim_replace_termcodes("<C-o>", true, false, true)
                                    end
                                    -- Keyboard scrolling preserves alignment across inserted/deleted lines.
                                    vim.api.nvim_feedkeys(prefix .. count .. input, "n", false)
                                    return
                                end
                                local input = vim.api.nvim_replace_termcodes(key, true, false, true)
                                vim.api.nvim_feedkeys(input, "n", false)
                            end, { buffer = buffer, desc = "Scroll diff panes together" })
                        end
                    end,
                },
                keymaps = {
                    view = { { "n", "q", "<cmd>DiffviewClose<CR>", { desc = "Close diff review" } } },
                    file_panel = { { "n", "q", "<cmd>DiffviewClose<CR>", { desc = "Close diff review" } } },
                },
            },
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
                local lazygit = require("toggleterm.terminal").Terminal:new {
                    cmd = "lazygit",
                    dir = "git_dir",
                    direction = "float",
                    display_name = " Lazygit ",
                    env = {},
                    float_opts = {
                        border = "curved",
                        winblend = 0,
                        width = function()
                            return math.max(1, vim.o.columns - 4)
                        end,
                        height = function()
                            return math.max(1, vim.o.lines - 4)
                        end,
                    },
                    highlights = {
                        NormalFloat = { link = "Normal" },
                        FloatBorder = { link = "NoiceCmdlinePopupBorder" },
                    },
                    hidden = true,
                    close_on_exit = true,
                    on_open = function()
                        vim.cmd "startinsert"
                    end,
                }
                vim.keymap.set("n", "<leader>gl", function()
                    local directory = vim.fn.stdpath "config" .. "/../lazygit/"
                    local configs = directory .. "config.yml"
                    if vim.o.background == "dark" then
                        configs = configs .. "," .. directory .. "dark.yml"
                    end
                    lazygit.cmd = "lazygit --use-config-file " .. vim.fn.shellescape(configs)
                    lazygit.env.NVIM_LAZYGIT_BACKGROUND = vim.o.background
                    lazygit.env.COLORTERM = "truecolor"
                    lazygit:toggle()
                end, { desc = "Toggle lazygit" })
            end,
        },
        {
            "lewis6991/gitsigns.nvim",
            config = function()
                require("gitsigns").setup()
            end,
        },
        {
            "tpope/vim-fugitive",
        },
    }
end

---Install navigation between Git changes in the current buffer.
function M.setup()
    vim.keymap.set("n", "<leader>g<Down>", function()
        if vim.wo.diff then
            vim.cmd "normal! ]c"
        else
            require("gitsigns").nav_hunk("next", { target = "all" })
        end
    end, { desc = "Next Git change" })
    vim.keymap.set("n", "<leader>g<Up>", function()
        if vim.wo.diff then
            vim.cmd "normal! [c"
        else
            require("gitsigns").nav_hunk("prev", { target = "all" })
        end
    end, { desc = "Previous Git change" })
end

return M
