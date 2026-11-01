-- Exercise inline and display math through the configured Markdown renderer.
-- Run with: nvim --headless -n -c "luafile configs/nvim/tests/math-integration.lua"
vim.defer_fn(function()
    local ok, err = xpcall(function()
        local api = vim.api
        local editor = assert(require("framed_layout").editor())
        api.nvim_set_current_win(editor)
        local buffer = api.nvim_create_buf(true, false)
        local lines = {
            "# Math rendering",
            "",
            "Inline: $\\alpha + \\beta$.",
            "",
            "$$",
            "\\frac{1}{1+x}",
            "$$",
            "",
            "$$",
            "G^* \\xrightarrow{I_{\\mathrm{assay}}} E \\xrightarrow{\\{P_i\\}} \\{V_i\\}",
            "\\longrightarrow X_s(q) \\longrightarrow Y_s(q).",
            "$$",
            "",
            "End of document.",
        }
        api.nvim_buf_set_name(buffer, vim.fn.tempname() .. ".md")
        api.nvim_buf_set_lines(buffer, 0, -1, false, lines)
        api.nvim_win_set_buf(editor, buffer)
        vim.bo[buffer].filetype = "markdown"
        api.nvim_win_set_cursor(editor, { #lines, 0 })
        require("render-markdown").enable()
        vim.cmd "redraw"
        local function rendered_rows()
            local rows = {}
            for _, mark in ipairs(api.nvim_buf_get_extmarks(buffer, -1, 0, -1, { details = true })) do
                local details = mark[4]
                local chunks = vim.deepcopy(details.virt_text or {})
                for _, line in ipairs(details.virt_lines or {}) do
                    vim.list_extend(chunks, line)
                end
                for _, chunk in ipairs(chunks) do
                    if chunk[2] == "RenderMarkdownMath" and chunk[1]:find "[^%s]" then
                        rows[mark[2]] = (rows[mark[2]] or "") .. chunk[1]
                    end
                end
            end
            return rows
        end
        assert(
            vim.wait(5000, function()
                local rows = rendered_rows()
                local output = table.concat(vim.tbl_values(rows), "\n")
                return rows[2]
                    and rows[7]
                    and output:find("assay", 1, true)
                    and output:find("P", 1, true)
                    and output:find(vim.fn.nr2char(0x2192), 1, true)
                    and not output:find("error", 1, true)
            end, 50),
            "Inline or display math did not produce rendered text"
        )
        local function concealed(row)
            for _, mark in ipairs(api.nvim_buf_get_extmarks(buffer, -1, 0, -1, { details = true })) do
                local details = mark[4]
                if details.conceal_lines and mark[2] <= row and details.end_row >= row then
                    return true
                end
            end
            return false
        end
        assert(concealed(4) and concealed(5) and concealed(6), "Display math source remained visible")
        assert(concealed(8) and concealed(11), "Labeled-arrow block remained visible")
        local function move(row)
            api.nvim_win_set_cursor(editor, { row, 0 })
            api.nvim_exec_autocmds("CursorMoved", { buffer = buffer })
            vim.cmd "redraw"
        end
        move(4)
        vim.cmd "normal! j"
        api.nvim_exec_autocmds("CursorMoved", { buffer = buffer })
        assert(api.nvim_win_get_cursor(editor)[1] == 5, "Keyboard navigation skipped the concealed equation")
        assert(
            vim.wait(2000, function()
                return not concealed(4)
            end, 20),
            "Keyboard navigation did not reveal the equation"
        )
        for _, row in ipairs { 5, 6, 7 } do
            move(row)
            assert(
                vim.wait(2000, function()
                    return not concealed(4)
                end, 20),
                "Display math did not reveal its complete source at row " .. row
            )
            assert(concealed(8), "Editing one equation revealed a separate equation")
            move(#lines)
            assert(
                vim.wait(2000, function()
                    return concealed(4) and rendered_rows()[7]
                end, 20),
                "Display math did not return after leaving its source"
            )
        end
        move(4)
        vim.cmd "normal! v"
        move(8)
        assert(
            vim.wait(2000, function()
                return not concealed(4)
            end, 20),
            "Selecting across an equation did not reveal its source"
        )
        vim.cmd.normal { args = { vim.api.nvim_replace_termcodes("<Esc>", true, false, true) }, bang = true }
        move(#lines)
        assert(
            vim.wait(2000, function()
                return concealed(4)
            end, 20),
            "Display math did not return after selection"
        )
        require("render-markdown").buf_disable()
        assert(
            vim.wait(2000, function()
                return not concealed(4) and vim.tbl_isempty(rendered_rows())
            end, 20),
            "Disabling Markdown rendering left math decorations behind"
        )
        vim.wait(200)
        require("render-markdown").buf_enable()
        assert(
            vim.wait(2000, function()
                return concealed(4) and rendered_rows()[7]
            end, 20),
            "Enabling Markdown rendering did not restore the equation"
        )
        assert(vim.deep_equal(api.nvim_buf_get_lines(buffer, 0, -1, false), lines), "Rendering changed Markdown source")
        assert(api.nvim_get_current_win() == editor, "Math rendering moved focus")
        print "PASS: inline/display math replacement, cursor/selection reveal, and source/focus preservation"
    end, debug.traceback)
    if not ok then
        print(err)
        vim.cmd "cquit"
    else
        vim.cmd "qa!"
    end
end, 1500)
