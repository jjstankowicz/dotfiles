-- Exercise source navigation and outline lifecycle in the active workspace.
-- Run with: nvim --headless -c "luafile configs/nvim/tests/outline-integration.lua"
vim.defer_fn(function()
    local ok, err = xpcall(function()
        local api = vim.api
        local layout = require "framed_layout"
        vim.o.columns = 160
        vim.o.lines = 44
        layout.resize()
        local editor = assert(layout.editor())
        local outline = assert(layout.outline())
        local expected = api.nvim_win_get_config(outline)
        local function assert_geometry()
            local actual = api.nvim_win_get_config(outline)
            for _, key in ipairs { "row", "col", "width", "height" } do
                assert(actual[key] == expected[key], "Outline changed its " .. key .. " while loading symbols")
            end
        end
        assert(#layout.panes() == 5)
        local files = layout.panes()[1]
        local graph = assert(layout.graph())
        local function navigate(key, expected_window)
            local input = vim.api.nvim_replace_termcodes(" w<" .. key .. ">", true, false, true)
            vim.fn.feedkeys(input, "xt")
            assert(api.nvim_get_current_win() == expected_window, "Pane arrow missed its destination: " .. key)
        end
        api.nvim_set_current_win(editor)
        navigate("Right", layout.panes()[4])
        navigate("Down", graph)
        navigate("Left", editor)
        navigate("Left", files)
        navigate("Down", outline)
        navigate("Right", editor)
        navigate("Right", graph)
        navigate("Up", layout.panes()[4])
        navigate("Left", editor)
        navigate("Left", outline)
        navigate("Up", files)
        navigate("Up", outline)
        navigate("Down", files)
        navigate("Left", layout.panes()[4])
        navigate("Right", files)
        navigate("Down", outline)
        navigate("Left", graph)
        navigate("Right", outline)
        layout.focus "left"
        assert(api.nvim_get_current_win() == outline, "Native pane navigation unexpectedly wrapped")
        navigate("Right", editor)
        assert(vim.fn.maparg(" <Left>", "n") == "ge" and vim.fn.maparg(" <Right>", "n") == "e")
        assert(vim.fn.maparg(" <Up>", "n") == "{" and vim.fn.maparg(" <Down>", "n") == "}")
        local function source(name, filetype, lines)
            local buffer = api.nvim_create_buf(true, false)
            api.nvim_buf_set_name(buffer, vim.fn.tempname() .. name)
            api.nvim_buf_set_lines(buffer, 0, -1, false, lines)
            vim.bo[buffer].filetype = filetype
            api.nvim_set_current_win(editor)
            api.nvim_win_set_buf(editor, buffer)
            return buffer
        end
        local function find_symbol(name)
            for index, line in ipairs(api.nvim_buf_get_lines(api.nvim_win_get_buf(outline), 0, -1, false)) do
                if line:find(name, 1, true) then
                    return index
                end
            end
        end
        local python = source(".py", "python", {
            "class Widget:",
            "    def first(self):",
            "        return 1",
            "",
            "    def second(self):",
            "        return 2",
            "",
            "def standalone():",
            "    return 3",
        })
        assert(
            vim.wait(3500, function()
                return find_symbol "Widget" and find_symbol "second" and find_symbol "standalone"
            end, 20),
            "Outline did not show Python class, methods, and function"
        )
        assert_geometry()
        assert(api.nvim_get_current_win() == editor, "Outline refresh stole editor focus")
        layout.focus "left"
        layout.focus "down"
        assert(api.nvim_get_current_win() == outline)
        api.nvim_win_set_cursor(outline, { assert(find_symbol "second"), 0 })
        vim.fn.maparg("<CR>", "n", false, true).callback()
        assert(api.nvim_get_current_win() == editor and api.nvim_win_get_cursor(editor)[1] == 5)
        assert(api.nvim_win_get_buf(editor) == python and api.nvim_win_get_buf(files) ~= python)
        local markdown = source(".md", "markdown", { "# Overview", "", "Text", "", "## Details", "", "More" })
        assert(
            vim.wait(3500, function()
                return find_symbol "Overview" and find_symbol "Details" and not find_symbol "Widget"
            end, 20),
            "Outline did not follow the editor's Markdown buffer"
        )
        assert_geometry()
        api.nvim_set_current_win(outline)
        api.nvim_win_set_cursor(outline, { assert(find_symbol "Details"), 0 })
        vim.fn.maparg("p", "n", false, true).callback()
        assert(api.nvim_get_current_win() == outline and api.nvim_win_get_cursor(editor)[1] == 5)
        layout.adjust_width(3)
        assert(api.nvim_win_get_width(outline) == api.nvim_win_get_width(files))
        local height = api.nvim_win_get_height(files)
        layout.toggle_outline()
        assert(not layout.outline() and api.nvim_win_get_height(files) > height)
        api.nvim_set_current_win(graph)
        navigate("Right", files)
        navigate("Up", files)
        navigate("Left", layout.panes()[3])
        layout.toggle_outline()
        outline = assert(layout.outline())
        assert(
            vim.wait(2000, function()
                return find_symbol "Details"
            end, 20),
            "Reopened outline lost its source"
        )
        assert(api.nvim_win_get_buf(editor) == markdown and api.nvim_buf_is_valid(python))
        layout.toggle_files()
        assert(not layout.outline(), "Outline remained after hiding Files")
        api.nvim_set_current_win(editor)
        navigate("Left", layout.panes()[2])
        navigate("Right", editor)
        layout.toggle_files()
        assert(layout.outline() and #layout.panes() == 5)
        layout.native()
        assert(not layout.outline() and not layout.graph() and #layout.panes() == 3)
        print "PASS: Python and Markdown outline, source switching, jump/preview, width, pane toggles, and native restoration"
    end, debug.traceback)
    if not ok then
        print(err)
        vim.cmd "cquit"
    else
        vim.cmd "qa!"
    end
end, 1500)
