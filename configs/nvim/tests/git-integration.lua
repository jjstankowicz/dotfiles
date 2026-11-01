-- Exercise real Git state changes and the active review plugins.
-- Run with: nvim --headless -c "luafile configs/nvim/tests/git-integration.lua"
vim.defer_fn(function()
    local directory = vim.fn.tempname()
    local ok, err = pcall(function()
        vim.o.columns = 160
        vim.o.lines = 42
        vim.fn.mkdir(directory, "p")
        vim.fn.writefile({ "original" }, directory .. "/tracked.txt")
        local navigation_lines = {}
        for line = 1, 40 do
            navigation_lines[line] = "Line " .. line
        end
        vim.fn.writefile(navigation_lines, directory .. "/navigation.txt")
        local function git(args)
            local command = { "git", "-C", directory }
            vim.list_extend(command, args)
            local output = vim.fn.system(command)
            assert(vim.v.shell_error == 0, output)
            return vim.trim(output)
        end
        local function close_diff()
            assert(
                vim.wait(3500, function()
                    local view = require("diffview.lib").get_current_view()
                    if not view or not view.cur_layout or not view.cur_layout:is_files_loaded() then
                        return false
                    end
                    for _, window in ipairs(view.cur_layout.windows) do
                        if not window:is_valid() or vim.api.nvim_win_get_buf(window.id) ~= window.file.bufnr then
                            return false
                        end
                    end
                    return true
                end, 20),
                "Diff buffers did not finish opening"
            )
            -- Finish queued scroll synchronization before destroying the diff windows.
            vim.wait(20)
            vim.cmd "DiffviewClose"
        end
        git { "init", "-q" }
        git { "add", "." }
        git { "-c", "user.name=Test", "-c", "user.email=test@example.invalid", "commit", "-qm", "Fixture" }
        local reference = git { "rev-parse", "HEAD" }
        local branch = "review-reference-with-a-long-name-for-preview"
        git { "branch", branch }
        local layout = require "framed_layout"
        if layout.outline() then
            layout.toggle_outline()
        end
        if layout.graph() then
            layout.toggle_graph()
        end
        layout.resize()
        local editor = layout.editor()
        navigation_lines[8] = "Staged change"
        vim.fn.writefile(navigation_lines, directory .. "/navigation.txt")
        git { "add", "navigation.txt" }
        navigation_lines[26] = "Unstaged change"
        vim.fn.writefile(navigation_lines, directory .. "/navigation.txt")
        layout.open_file(directory .. "/navigation.txt")
        assert(
            vim.wait(3500, function()
                local cache = require("gitsigns.cache").cache[vim.api.nvim_get_current_buf()]
                local hunks = cache and cache.hunks
                local staged = cache and cache.hunks_staged
                return hunks and #hunks > 0 and staged and #staged > 0
            end, 20),
            "Git signs did not load staged and unstaged changes"
        )
        vim.api.nvim_win_set_cursor(editor, { 1, 0 })
        vim.fn.maparg(" g<Down>", "n", false, true).callback()
        assert(
            vim.wait(1000, function()
                return vim.api.nvim_win_get_cursor(editor)[1] == 8
            end, 10),
            "Next change skipped the staged hunk"
        )
        vim.fn.maparg(" g<Down>", "n", false, true).callback()
        assert(
            vim.wait(1000, function()
                return vim.api.nvim_win_get_cursor(editor)[1] == 26
            end, 10),
            "Next change missed the unstaged hunk"
        )
        vim.fn.maparg(" g<Up>", "n", false, true).callback()
        assert(
            vim.wait(1000, function()
                return vim.api.nvim_win_get_cursor(editor)[1] == 8
            end, 10),
            "Previous change skipped the staged hunk"
        )
        local manager = require "neo-tree.sources.manager"
        local state = manager.get_state "git_status"
        local window = state.winid
        manager.navigate(state, directory)
        require("git_panel_refresh").setup()
        vim.fn.writefile({ "changed" }, directory .. "/tracked.txt")
        vim.fn.writefile({ "new" }, directory .. "/new.txt")
        assert(
            vim.wait(3500, function()
                return state.tree:get_node(directory .. "/new.txt") ~= nil
            end, 20),
            "Auto-refresh did not pick up external changes"
        )
        assert(state.winid == window and vim.api.nvim_win_get_config(window).relative == "editor")
        assert(vim.api.nvim_get_current_win() == editor and #layout.panes() == 3)
        git { "add", "tracked.txt" }
        git { "-c", "user.name=Test", "-c", "user.email=test@example.invalid", "commit", "-qm", "Committed update" }
        local tip = git { "rev-parse", "HEAD" }
        vim.fn.writefile({ "uncommitted after update" }, directory .. "/tracked.txt")
        layout.toggle_graph()
        local graph = assert(layout.graph())
        assert(vim.wait(1000, function()
            return vim.bo[vim.api.nvim_win_get_buf(graph)].filetype == "workspace_git_graph"
        end, 10))
        require("git_graph").attach(graph, directory)
        local fixture_line, tip_line
        assert(
            vim.wait(3500, function()
                local lines = vim.api.nvim_buf_get_lines(vim.api.nvim_win_get_buf(graph), 0, -1, false)
                for index, line in ipairs(lines) do
                    if line:find("Fixture", 1, true) and line:find("review-reference", 1, true) then
                        fixture_line = index
                    end
                    if line:find("Committed update", 1, true) then
                        tip_line = index
                    end
                end
                return fixture_line ~= nil and table.concat(lines, "\n"):find("Committed update", 1, true) ~= nil
            end, 20),
            "Graph did not show both history and branch labels: "
                .. table.concat(vim.api.nvim_buf_get_lines(vim.api.nvim_win_get_buf(graph), 0, -1, false), "\n")
        )
        assert(#layout.panes() == 4 and vim.api.nvim_get_current_win() == editor)
        layout.focus "right"
        layout.focus "down"
        assert(vim.api.nvim_get_current_win() == graph, "Vertical navigation missed the commit graph")
        local graph_width = vim.api.nvim_win_get_width(graph)
        layout.adjust_width(3)
        assert(vim.api.nvim_win_get_width(graph) == graph_width + 3)
        assert(vim.api.nvim_win_get_width(window) == vim.api.nvim_win_get_width(graph))
        vim.api.nvim_win_set_cursor(graph, { fixture_line, 0 })
        local preview, popup = require("git_graph").preview(graph)
        assert(preview and popup and vim.api.nvim_win_is_valid(popup))
        assert(vim.wo[popup].winblend == require("theme").popup_blend, "Commit popup lost its transparency")
        local details = table.concat(vim.api.nvim_buf_get_lines(preview, 0, -1, false), "\n")
        assert(details:find(branch, 1, true) and details:find(reference, 1, true))
        assert(vim.api.nvim_get_current_win() == graph and vim.wo[popup].wrap)
        local preview_config = vim.api.nvim_win_get_config(popup)
        local editor_position = vim.fn.win_screenpos(editor)
        assert(preview_config.relative == "editor" and preview_config.width > vim.api.nvim_win_get_width(graph))
        assert(
            preview_config.col + preview_config.width + 2 == editor_position[2] - 1 + vim.api.nvim_win_get_width(editor)
        )
        vim.fn.maparg("<Esc>", "n", false, true).callback()
        assert(not vim.api.nvim_win_is_valid(popup))
        require("git_graph").select(graph, { working_tree = true })
        assert(
            vim.wait(3500, function()
                local view = require("diffview.lib").get_current_view()
                return view and view.cur_entry
            end, 20),
            "Diffview did not open from framed editor"
        )
        local view = require("diffview.lib").get_current_view()
        assert(view.left.commit == reference, "Graph selected the wrong historical commit")
        assert(view.right.type == require("diffview.vcs.rev").RevType.LOCAL, "Graph did not compare with working files")
        assert(git { "rev-parse", "HEAD" } ~= reference, "Graph selection checked out the historical commit")
        close_diff()
        vim.api.nvim_set_current_win(graph)
        vim.api.nvim_win_set_cursor(graph, { assert(tip_line), 0 })
        vim.fn.maparg("<CR>", "n", false, true).callback()
        assert(
            vim.wait(3500, function()
                local current = require("diffview.lib").get_current_view()
                return current and current.cur_entry
            end, 20),
            "Commit diff did not open"
        )
        view = require("diffview.lib").get_current_view()
        assert(
            view.left.commit == reference and view.right.commit == tip,
            "Commit diff did not compare with its parent"
        )
        assert(view.right.type == require("diffview.vcs.rev").RevType.COMMIT, "Commit diff includes working files")
        close_diff()
        vim.api.nvim_set_current_win(graph)
        vim.api.nvim_win_set_cursor(graph, { fixture_line, 0 })
        require("git_graph").select(graph)
        assert(
            vim.wait(3500, function()
                local current = require("diffview.lib").get_current_view()
                return current and current.cur_entry
            end, 20),
            "Initial commit diff did not open"
        )
        view = require("diffview.lib").get_current_view()
        assert(
            view.right.commit == reference
                and view.left.commit == require("diffview.vcs.adapters.git.rev").GitRev.NULL_TREE_SHA
        )
        close_diff()
        assert(layout.editor() == editor and #layout.panes() == 4 and layout.graph() == graph)
        assert(vim.api.nvim_win_get_config(editor).relative == "editor")
        layout.toggle_graph()
        assert(#layout.panes() == 3 and vim.api.nvim_get_current_win() == editor)
        vim.fn.maparg(" gl", "n", false, true).callback()
        local terminal
        for _, candidate in pairs(require("toggleterm.terminal").get_all(true)) do
            if candidate.cmd:find("lazygit", 1, true) then
                terminal = candidate
            end
        end
        assert(terminal and terminal:is_open())
        terminal:close()
        vim.fn.jobstop(terminal.job_id)
        assert(vim.api.nvim_get_current_win() == editor and #layout.panes() == 3)
        print "PASS: staged/unstaged hunk navigation, Git auto-refresh, compact branch graph, historical-to-working diff, graph navigation/resizing/toggle, and lazygit overlay"
    end)
    require("git_panel_refresh").stop()
    vim.fn.delete(directory, "rf")
    if not ok then
        print(err)
        vim.cmd "cquit"
    else
        vim.cmd "qa!"
    end
end, 1500)
