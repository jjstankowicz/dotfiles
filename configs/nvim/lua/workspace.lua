local M = {}

local function update_window_title()
    if vim.bo.buftype ~= "" then
        return
    end
    local file = vim.api.nvim_buf_get_name(0)
    local directory = file ~= "" and vim.fn.fnamemodify(file, ":h") or vim.fn.getcwd()
    local status = vim.b.gitsigns_status_dict or {}
    local root = status.root or vim.fs.root(directory, ".git") or vim.fn.getcwd()
    local project = vim.fn.fnamemodify(root, ":t")
    local branch = status.head and status.head ~= "" and " [" .. status.head .. "]" or ""
    local filename = file ~= "" and vim.fn.fnamemodify(file, ":t") or "[No Name]"
    local title = project .. branch .. " / " .. filename .. " | Neovim"
    vim.o.titlestring = title:gsub("%%", "%%%%"):gsub("[%c]", " ")
end

local function show_sidebars()
    local editor = require("framed_layout").editor() or vim.api.nvim_get_current_win()
    require("framed_layout").native()
    vim.api.nvim_set_current_win(editor)
    require("nvim-tree.api").tree.open { focus = false }
    if vim.bo[vim.api.nvim_win_get_buf(editor)].filetype == "NvimTree" then
        editor = nil
        for _, window in ipairs(vim.api.nvim_tabpage_list_wins(0)) do
            local filetype = vim.bo[vim.api.nvim_win_get_buf(window)].filetype
            if
                filetype ~= "NvimTree"
                and filetype ~= "neo-tree"
                and vim.api.nvim_win_get_config(window).relative == ""
            then
                editor = window
                break
            end
        end
        if not editor then
            vim.cmd "rightbelow vnew"
            editor = vim.api.nvim_get_current_win()
        end
    end
    vim.api.nvim_set_current_win(editor)
    require("neo-tree.command").execute {
        source = "git_status",
        position = "right",
        action = "show",
    }
    vim.api.nvim_set_current_win(editor)
    require("framed_layout").attach(
        editor,
        require("nvim-tree.view").get_winnr(),
        require("neo-tree.sources.manager").get_state("git_status").winid
    )
    vim.schedule(function()
        if vim.api.nvim_win_is_valid(editor) then
            vim.api.nvim_set_current_win(editor)
        end
    end)
end

---Return file and Git sidebar specifications.
function M.plugins()
    return {
        -- File Explorer
        {
            "nvim-tree/nvim-tree.lua",
            dependencies = { "nvim-tree/nvim-web-devicons" },
            config = function()
                require("nvim-tree").setup {
                    on_attach = function(buffer)
                        local api = require "nvim-tree.api"
                        api.config.mappings.default_on_attach(buffer)
                        local function open_file()
                            local node = api.tree.get_node_under_cursor()
                            if not node then
                                return
                            end
                            if node.type == "directory" or node.nodes then
                                api.node.open.edit(node)
                            elseif not require("framed_layout").open_file(node.link_to or node.absolute_path) then
                                api.node.open.edit(node)
                            end
                        end
                        for _, key in ipairs { "<CR>", "o", "O", "<2-LeftMouse>" } do
                            vim.keymap.set("n", key, open_file, { buffer = buffer, desc = "Open file in editor" })
                        end
                        for key, action in pairs {
                            ["<C-v>"] = api.node.open.vertical,
                            ["<C-x>"] = api.node.open.horizontal,
                            ["<C-t>"] = api.node.open.tab,
                        } do
                            vim.keymap.set("n", key, function()
                                require("framed_layout").native()
                                action()
                            end, {
                                buffer = buffer,
                                desc = "Open file in a native split or tab",
                            })
                        end
                        vim.keymap.set("n", "<Tab>", function()
                            local node = api.tree.get_node_under_cursor()
                            local window = vim.api.nvim_get_current_win()
                            if
                                node
                                and node.type ~= "directory"
                                and require("framed_layout").open_file(node.link_to or node.absolute_path)
                            then
                                vim.api.nvim_set_current_win(window)
                            else
                                api.node.open.preview(node)
                            end
                        end, { buffer = buffer, desc = "Preview file in editor" })
                    end,
                    filters = { dotfiles = true },
                    view = { width = 30, side = "left", signcolumn = "no" },
                    renderer = {
                        icons = { diagnostics_placement = "after", bookmarks_placement = "after" },
                    },
                    git = { enable = true },
                }

                -- <leader>x to toggle the file tree
                vim.keymap.set("n", "<leader>x", function()
                    require("framed_layout").toggle_files()
                end, {
                    noremap = true,
                    silent = true,
                    desc = "Toggle file sidebar",
                })
            end,
        },
        -- Git sidebar
        {
            "nvim-neo-tree/neo-tree.nvim",
            branch = "v3.x",
            dependencies = {
                "nvim-lua/plenary.nvim",
                "MunifTanjim/nui.nvim",
                "nvim-tree/nvim-web-devicons",
            },
            cmd = "Neotree",
            keys = {
                {
                    "<leader>gg",
                    function()
                        require("framed_layout").toggle_git()
                    end,
                    desc = "Toggle Git sidebar",
                },
                {
                    "<leader>gs",
                    show_sidebars,
                    desc = "Show file and Git sidebars",
                },
            },
            opts = {
                sources = { "git_status" },
                default_source = "git_status",
                enable_diagnostics = false,
                event_handlers = {
                    {
                        event = "file_open_requested",
                        handler = function(args)
                            if
                                (args.open_cmd == "edit" or args.open_cmd == "buffer")
                                and require("framed_layout").open_file(args.path, args.bufnr)
                            then
                                return { handled = true }
                            end
                            require("framed_layout").native()
                        end,
                    },
                    {
                        event = "after_render",
                        handler = function()
                            require("framed_layout").resize()
                        end,
                    },
                },
                open_files_do_not_replace_types = { "terminal", "Trouble", "qf", "edgy", "NvimTree" },
                git_status = {
                    window = {
                        position = "right",
                        width = 30,
                        mappings = {
                            ["d"] = function(state)
                                local node = state.tree:get_node()
                                if node and node.type == "file" then
                                    require("neo-tree.sources.git_status.commands").open(state)
                                    require("framed_layout").native()
                                    vim.cmd "Gvdiffsplit"
                                end
                            end,
                        },
                    },
                },
            },
            config = function(_, opts)
                require("neo-tree").setup(opts)
                require("git_panel_refresh").setup()
            end,
        },
    }
end

---Install terminal titles, pane navigation, and the initial workspace layout.
function M.setup()
    if vim.g.workspace_code_outline == nil then
        vim.g.workspace_code_outline = true
    end
    vim.keymap.set("n", "<leader>fo", function()
        require("framed_layout").toggle_outline()
    end, { desc = "Toggle code outline" })
    if vim.g.workspace_git_graph == nil then
        vim.g.workspace_git_graph = true
    end
    vim.keymap.set("n", "<leader>gh", function()
        require("framed_layout").toggle_graph()
    end, { desc = "Toggle Git history graph" })
    local title_group = vim.api.nvim_create_augroup("TerminalWindowTitle", { clear = true })
    vim.api.nvim_create_autocmd({ "VimEnter", "BufEnter", "BufFilePost", "DirChanged", "FocusGained" }, {
        group = title_group,
        callback = update_window_title,
    })
    vim.api.nvim_create_autocmd("User", {
        group = title_group,
        pattern = "GitSignsUpdate",
        callback = update_window_title,
    })

    for key, direction in pairs { Left = "left", Right = "right", Up = "up", Down = "down" } do
        local focus = function()
            require("framed_layout").focus(direction)
        end
        vim.keymap.set("n", "<leader>w<" .. key .. ">", function()
            require("framed_layout").focus(direction, true)
        end, { desc = "Focus pane " .. direction })
        if direction == "left" or direction == "right" then
            vim.keymap.set("n", direction == "left" and "<C-w>h" or "<C-w>l", focus)
        end
    end

    require("framed_layout").setup()
    vim.api.nvim_create_autocmd("VimEnter", {
        once = true,
        callback = function()
            if vim.g.standard_mode ~= 1 then
                vim.schedule(show_sidebars)
            end
        end,
    })
end

return M
