-- Exercise the active configuration and actual sidebar plugins.
-- Run with: nvim --headless -c "luafile configs/nvim/tests/workspace-integration.lua"
local function finish(ok, err)
    if not ok then
        print(err)
        vim.cmd "cquit"
    else
        print "PASS: rounded workspace, theme mappings, sidebar opening/toggles, retained widths, buffers, native splits, mouse dragging and ordinary clicks"
        vim.cmd "qa!"
    end
end

local function mouse_regression()
    local layout = require "framed_layout"
    local editor = layout.editor()
    local files, git
    for _, window in ipairs(layout.panes()) do
        local filetype = vim.bo[vim.api.nvim_win_get_buf(window)].filetype
        if filetype == "NvimTree" then
            files = window
        elseif filetype == "neo-tree" then
            git = window
        end
    end
    layout.attach(editor, files, git)
    vim.o.columns = 160
    vim.o.lines = 42
    vim.o.mouse = "a"
    layout.resize()
    local panes = layout.panes()
    local buffer = vim.api.nvim_win_get_buf(editor)
    local cursor = vim.api.nvim_win_get_cursor(editor)
    local file_config = vim.api.nvim_win_get_config(files)
    local row = file_config.row + 2
    local edge = file_config.col + file_config.width + 1
    local git_edge, git_width, popup
    local steps = {
        function()
            vim.cmd "redraw"
            vim.api.nvim_input_mouse("left", "press", "", 0, row, edge)
        end,
        function()
            vim.api.nvim_input_mouse("left", "drag", "", 0, row, edge + 7)
        end,
        function()
            vim.api.nvim_input_mouse("left", "release", "", 0, row, edge + 7)
        end,
        function()
            assert(vim.api.nvim_win_get_width(files) == file_config.width + 7, "File border drag failed")
            assert(vim.api.nvim_get_current_win() == editor, "Border drag changed editor focus")
            assert(vim.deep_equal(vim.api.nvim_win_get_cursor(editor), cursor), "Border drag changed the cursor")
            local config = vim.api.nvim_win_get_config(git)
            git_edge, git_width = config.col, config.width
            vim.api.nvim_input_mouse("left", "press", "", 0, row, git_edge)
        end,
        function()
            vim.api.nvim_input_mouse("left", "drag", "", 0, row, git_edge - 5)
        end,
        function()
            vim.api.nvim_input_mouse("left", "release", "", 0, row, git_edge - 5)
        end,
        function()
            assert(vim.api.nvim_win_get_width(git) == git_width + 5, "Git border drag failed")
            assert(vim.api.nvim_get_current_win() == editor, "Git border drag changed focus")
            assert(vim.deep_equal(layout.panes(), panes), "Mouse dragging replaced workspace panes")
            assert(vim.api.nvim_win_get_buf(editor) == buffer, "Mouse dragging replaced the editor buffer")
            vim.api.nvim_input_mouse("left", "press", "", 0, row, 2)
        end,
        function()
            vim.api.nvim_input_mouse("left", "release", "", 0, row, 2)
        end,
        function()
            assert(vim.api.nvim_get_current_win() == files, "Ordinary file-pane click stopped working")
            local config = vim.api.nvim_win_get_config(files)
            edge = config.col + config.width + 1
            popup = vim.api.nvim_open_win(vim.api.nvim_create_buf(false, true), false, {
                relative = "editor",
                row = row - 1,
                col = edge - 1,
                width = 10,
                height = 3,
                zindex = 100,
            })
            vim.cmd "redraw"
            vim.api.nvim_input_mouse("left", "press", "", 0, row, edge)
        end,
        function()
            vim.api.nvim_input_mouse("left", "drag", "", 0, row, edge + 3)
        end,
        function()
            vim.api.nvim_input_mouse("left", "release", "", 0, row, edge + 3)
        end,
        function()
            assert(vim.api.nvim_win_get_width(files) == file_config.width + 7, "Popup click resized a pane underneath")
            vim.api.nvim_win_close(popup, true)
            vim.api.nvim_set_current_win(files)
            vim.api.nvim_input "<Esc>:vertical resize 40<CR>"
        end,
        function()
            layout.resize()
            assert(vim.api.nvim_win_get_width(files) == 40, "Explicit vertical resize was not retained")
            vim.api.nvim_input ":vertical resize +3<CR>"
        end,
        function()
            assert(vim.api.nvim_win_get_width(files) == 43, "Relative vertical resize was not retained")
        end,
    }
    local index = 0
    local function next_step()
        index = index + 1
        if not steps[index] then
            finish(true)
            return
        end
        local ok, err = pcall(steps[index])
        if not ok then
            finish(false, err)
            return
        end
        -- Mouse input must return to Neovim's normal event loop before the next event.
        vim.defer_fn(next_step, 50)
    end
    next_step()
end

vim.defer_fn(function()
    local ok, err = pcall(function()
        local layout = require "framed_layout"
        if layout.outline() then
            layout.toggle_outline()
        end
        if layout.graph() then
            layout.toggle_graph()
        end
        local editor = layout.editor()
        assert(#layout.panes() == 3)
        for _, window in ipairs(layout.panes()) do
            local config = vim.api.nvim_win_get_config(window)
            assert(config.relative == "editor")
            assert(config.border[1] == "" and config.border[3] == "")
            assert(config.border[5] == vim.fn.nr2char(0x1fbef))
            assert(config.border[7] == vim.fn.nr2char(0x1fbec))
        end
        local headers = {}
        for _, window in ipairs(vim.api.nvim_tabpage_list_wins(0)) do
            local buffer = vim.api.nvim_win_get_buf(window)
            if vim.bo[buffer].filetype == "framed-header" then
                local config = vim.api.nvim_win_get_config(window)
                assert(config.row == 0 and config.height == 1 and not config.focusable)
                assert(config.border[1] == vim.fn.nr2char(0x1fbee))
                assert(config.border[3] == vim.fn.nr2char(0x1fbed))
                headers[vim.trim(vim.api.nvim_buf_get_lines(buffer, 0, 1, false)[1])] = true
            end
        end
        assert(headers.Files and headers.Editor and headers.Git)
        layout.focus "left"
        assert(vim.bo.filetype == "NvimTree")
        layout.adjust_width(5)
        local file_width = vim.api.nvim_win_get_width(0)
        layout.focus "right"
        assert(vim.api.nvim_get_current_win() == editor)
        layout.focus "right"
        assert(vim.bo.filetype == "neo-tree")
        layout.focus "left"
        local api = require "nvim-tree.api"
        local path = assert(vim.uv.fs_realpath(vim.fn.stdpath "config")) .. "/lua/framed_layout.lua"
        api.tree.find_file { buf = vim.fn.bufadd(path), open = true, focus = true }
        vim.fn.maparg("<CR>", "n", false, true).callback()
        assert(vim.api.nvim_get_current_win() == editor and vim.api.nvim_buf_get_name(0) == path)
        require("neo-tree.utils").open_file(
            require("neo-tree.sources.manager").get_state "git_status",
            vim.fn.stdpath "config" .. "/init.lua",
            "edit"
        )
        assert(
            vim.api.nvim_get_current_win() == editor and vim.fn.expand "%:t" == "init.lua",
            "Git file opening failed"
        )
        layout.toggle_files()
        assert(#layout.panes() == 2)
        layout.toggle_files()
        assert(#layout.panes() == 3)
        assert(vim.api.nvim_win_get_width(layout.panes()[1]) == file_width, "File toggle reset its preferred width")
        layout.toggle_git()
        assert(#layout.panes() == 2)
        layout.toggle_git()
        assert(#layout.panes() == 3)
        vim.o.columns = 120
        vim.o.lines = 35
        layout.resize()
        local config = vim.api.nvim_win_get_config(editor)
        local offsets = require("bufferline.offset").get()
        assert(offsets.left_size == 0 and offsets.right_size == 0)
        assert(offsets.total_size + config.width == vim.o.columns)
        assert(vim.o.showtabline == 0 and config.row == 2)
        assert(config.title == nil, "Pane title interrupts its border")
        assert(vim.wo[editor].winbar ~= "")
        assert(vim.wo[layout.panes()[1]].winbar == "" and vim.wo[layout.panes()[3]].winbar == "")
        local file = vim.api.nvim_get_current_buf()
        layout.focus "left"
        local bar = vim.api.nvim_eval_statusline(vim.wo[editor].winbar, { winid = editor, use_winbar = true })
        assert(bar.str:find("init.lua", 1, true), "Editor bar lost its file while sidebar had focus")
        require("bufferline.config").options.left_mouse_command(file)
        assert(vim.api.nvim_get_current_win() == editor and vim.api.nvim_get_current_buf() == file)
        vim.cmd.enew()
        vim.api.nvim_buf_set_name(0, vim.fn.tempname())
        vim.api.nvim_eval_statusline(vim.wo[editor].winbar, { winid = editor, use_winbar = true })
        local closed = vim.api.nvim_get_current_buf()
        vim.cmd "BufferClose"
        assert(not vim.api.nvim_buf_is_valid(closed))
        assert(vim.api.nvim_buf_is_valid(file))
        assert(vim.api.nvim_get_current_buf() == file)
        assert(#layout.panes() == 3)
        vim.fn.maparg(" gs", "n", false, true).callback()
        assert(#layout.panes() == 3 and layout.editor() == editor)
        layout.native()
        assert(#layout.panes() == 3)
        assert(vim.o.showtabline == 2 and vim.wo[editor].winbar == "")
        for _, window in ipairs(layout.panes()) do
            assert(vim.api.nvim_win_get_config(window).relative == "")
        end
    end)
    if not ok then
        finish(false, err)
    else
        local started, failure = pcall(mouse_regression)
        if not started then
            finish(false, failure)
        end
    end
end, 1500)
