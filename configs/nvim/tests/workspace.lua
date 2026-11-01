-- Run with Neovim 0.11+: nvim --headless -u NONE -c "luafile configs/nvim/tests/workspace.lua"
local source = debug.getinfo(1, "S").source:sub(2)
local config = vim.fn.fnamemodify(source, ":p:h:h")
package.path = config .. "/lua/?.lua;" .. package.path

-- Isolate the pinned Bufferline adapter; exercise actual Neovim window and command events.
package.loaded["bufferline.offset"] = {
    get = function()
        return { total_size = 0, left_size = 0, right_size = 0, left = "", right = "" }
    end,
}
_G.nvim_bufferline = function()
    return "%#Normal#%="
end

local layout = require "framed_layout"
layout.setup()

local function workspace()
    layout.native()
    vim.cmd "only!"
    local editor = vim.api.nvim_get_current_win()
    local buffer = vim.api.nvim_create_buf(true, false)
    vim.api.nvim_win_set_buf(editor, buffer)
    vim.api.nvim_buf_set_lines(buffer, 0, -1, false, { "split target", "second line" })
    vim.bo[buffer].modified = false
    vim.cmd "leftabove vnew"
    local files = vim.api.nvim_get_current_win()
    vim.api.nvim_set_current_win(editor)
    vim.cmd "rightbelow vnew"
    local git = vim.api.nvim_get_current_win()
    layout.attach(editor, files, git)
    return { files, editor, git }, buffer
end

local function type_command(keys)
    vim.api.nvim_feedkeys(vim.api.nvim_replace_termcodes(keys, true, false, true), "xt", false)
end

local function assert_framed(panes, buffer)
    assert(vim.deep_equal(layout.panes(), panes), "Workspace pane identities changed")
    for _, window in ipairs(panes) do
        assert(vim.api.nvim_win_get_config(window).relative == "editor", "Workspace lost its frame")
    end
    assert(vim.api.nvim_win_get_buf(panes[2]) == buffer, "Editor buffer changed")
end

local function main()
    vim.o.columns = 160
    vim.o.lines = 42
    vim.o.mouse = "a"
    vim.o.laststatus = 3
    local panes, buffer = workspace()
    type_command ":split<Esc>"
    assert_framed(panes, buffer)
    type_command "/split<CR>"
    assert_framed(panes, buffer)
    type_command "?split<CR>"
    assert_framed(panes, buffer)
    layout.focus "left"
    assert(vim.api.nvim_get_current_win() == panes[1], "Left navigation missed the file pane")
    layout.focus "right"
    layout.focus "right"
    assert(vim.api.nvim_get_current_win() == panes[3], "Right navigation missed the Git pane")
    layout.focus "left"
    layout.resize()
    assert_framed(panes, buffer)
    assert(vim.wo[panes[2]].winhighlight:find("Normal:FramedNormal,", 1, true), "Active editor lost its body highlight")
    assert(
        vim.wo[panes[1]].winhighlight:find("Normal:FramedNormalNC,", 1, true),
        "Inactive files lost their body highlight"
    )
    assert(vim.wo[panes[1]].winhighlight:find("LineNr:FramedLineNrNC", 1, true), "Inactive gutter lost its highlight")
    assert(
        vim.wo[panes[2]].winhighlight:find("FloatTitle:FramedPaneTitle,", 1, true),
        "Active title lost its highlight"
    )

    vim.api.nvim_set_current_win(panes[1])
    type_command "5<C-w>>"
    assert(vim.api.nvim_win_get_width(panes[1]) == 35, "Counted sidebar resize failed")
    vim.api.nvim_set_current_win(panes[2])
    type_command "3<C-w>>"
    assert(vim.api.nvim_win_get_width(panes[3]) == 27, "Editor resize did not adjust the right boundary")
    layout.focus "left"
    layout.focus "right"
    layout.resize()
    assert(vim.api.nvim_win_get_width(panes[1]) == 35, "Focus or redraw reset the requested width")
    vim.o.columns = 65
    layout.resize()
    assert(vim.api.nvim_win_get_width(panes[2]) >= 20, "Shrinking the terminal consumed the editor")
    vim.o.columns = 160
    layout.resize()
    assert(vim.api.nvim_win_get_width(panes[1]) == 35, "Terminal shrink discarded the preferred sidebar width")
    assert(vim.api.nvim_win_get_width(panes[3]) == 27, "Terminal shrink discarded the preferred Git width")

    type_command "<C-w>="
    local equal = vim.api.nvim_win_get_width(panes[1])
    assert(math.abs(vim.api.nvim_win_get_width(panes[2]) - equal) <= 2, "Equalizing left unequal panes")
    assert(vim.api.nvim_win_get_width(panes[3]) == equal, "Equalizing left unequal sidebars")

    layout.native()
    local width = vim.api.nvim_win_get_width(panes[2])
    type_command "3<C-w>>"
    assert(vim.api.nvim_win_get_width(panes[2]) == width + 3, "Native resize lost its count")

    for _, command in ipairs { "sp", "vsp", "vertical 2split", "silent belowright 2vsplit", "new", "vnew" } do
        panes, buffer = workspace()
        type_command(":" .. command .. "<CR>")
        assert(#vim.api.nvim_tabpage_list_wins(0) == 4, command .. " did not create one native split")
        for _, window in ipairs(vim.api.nvim_tabpage_list_wins(0)) do
            assert(vim.api.nvim_win_get_config(window).relative == "", command .. " left a floating pane")
            assert(
                not vim.wo[window].winhighlight:find("FramedNormal", 1, true),
                "Native pane retained framed highlights"
            )
        end
        assert(vim.api.nvim_win_get_buf(panes[2]) == buffer, command .. " replaced the original editor buffer")
    end
    print "PASS: framed command guards, pane navigation, retained widths, terminal shrinking, counted resizing, equalizing, and native split restoration"
end

-- UI geometry changes require normal startup and event processing.
vim.defer_fn(function()
    local ok, err = xpcall(main, debug.traceback)
    if not ok then
        vim.api.nvim_err_writeln(err)
        vim.cmd "cquit 1"
    end
    vim.cmd "qa!"
end, 100)
