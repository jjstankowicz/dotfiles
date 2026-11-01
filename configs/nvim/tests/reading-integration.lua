-- Exercise reading cues and mouse scrolling in the active framed workspace.
-- Run with: nvim --headless -c "luafile configs/nvim/tests/reading-integration.lua"
local function test()
    local api = vim.api
    assert(require("ibl").initialized, "Indent guides failed during startup")
    for _, background in ipairs { "dark", "light" } do
        vim.o.background = background
        vim.cmd.colorscheme "vscode_modern"
        assert(#require("ibl.highlights").indent > 0 and #require("ibl.highlights").scope > 0)
    end
    vim.o.columns = 160
    vim.o.lines = 44
    local editor = assert(require("framed_layout").editor())
    api.nvim_set_current_win(editor)
    local buffer = api.nvim_create_buf(true, false)
    api.nvim_buf_set_name(buffer, "/tmp/reading-check.py")
    local lines = { "def long_function():" }
    for i = 2, 220 do
        lines[i] = "    value_" .. i .. " = " .. i
    end
    lines[221] = "    return value_220"
    api.nvim_buf_set_lines(buffer, 0, -1, false, lines)
    api.nvim_win_set_buf(editor, buffer)
    vim.bo[buffer].filetype = "python"
    require("framed_layout").resize()
    api.nvim_win_set_cursor(editor, { 100, 4 })
    vim.fn.winrestview { topline = 80 }
    vim.cmd "redraw"
    api.nvim_exec_autocmds("CursorMoved", { buffer = buffer })
    vim.wait(500)
    local context = false
    for _, win in ipairs(api.nvim_list_wins()) do
        if vim.w[win].treesitter_context then
            local config = api.nvim_win_get_config(win)
            assert(config.relative == "win" and config.win == editor)
            assert(api.nvim_win_get_height(win) <= 2)
            context = true
        end
    end
    assert(context, "No sticky context over the real editor float")
    require("scrollview").refresh()
    vim.wait(300)
    local bars = {}
    for _, win in ipairs(api.nvim_list_wins()) do
        local props = vim.w[win].scrollview_props
        if props then
            bars[#bars + 1] = props
        end
    end
    assert(#bars > 0, "No scrollbars over overflowing panes")
    local editor_bar
    for _, props in ipairs(bars) do
        if props.parent_winid == editor and props.type == 0 then
            editor_bar = props
        end
    end
    assert(editor_bar, "Editor scrollbar missing")
    for _, pane in ipairs(require("framed_layout").panes()) do
        local pane_buffer = api.nvim_win_get_buf(pane)
        if api.nvim_buf_line_count(pane_buffer) > api.nvim_win_get_height(pane) then
            local found = false
            for _, props in ipairs(bars) do
                found = found or (props.parent_winid == pane and props.type == 0)
            end
            assert(found, "Overflowing pane has no scrollbar: " .. vim.bo[pane_buffer].filetype)
        end
    end
    for _, props in ipairs(bars) do
        assert(vim.bo[api.nvim_win_get_buf(props.parent_winid)].filetype ~= "framed-header")
    end
    local previous_topline = vim.fn.line("w0", editor)
    local geometry = vim.fn.win_screenpos(editor_bar.scrollview_winid)
    local row, col = geometry[1] - 1, geometry[2] - 1
    local width = api.nvim_win_get_width(editor)
    api.nvim_input_mouse("left", "press", "", 0, row, col)
    vim.defer_fn(function()
        api.nvim_input_mouse("left", "drag", "", 0, row + 8, col)
    end, 40)
    vim.defer_fn(function()
        api.nvim_input_mouse("left", "release", "", 0, row + 8, col)
    end, 80)
    vim.defer_fn(function()
        local ok, err = xpcall(function()
            assert(vim.fn.line("w0", editor) > previous_topline, "Scrollbar mouse drag did not scroll")
            assert(api.nvim_win_get_width(editor) == width, "Scrollbar drag resized editor")
            assert(vim.fn.maparg("<LeftMouse>", "n", false, true).callback, "Frame mouse map lost")
            print "PASS: Python context above real float, two-line cap, configured scope, scrollbar rendered and mouse drag preserved"
        end, debug.traceback)
        if not ok then
            print(err)
            vim.cmd "cquit"
        else
            vim.cmd "qa!"
        end
    end, 400)
end
vim.defer_fn(function()
    local ok, err = xpcall(test, debug.traceback)
    if not ok then
        print(err)
        vim.cmd "cquit"
    end
end, 1200)
