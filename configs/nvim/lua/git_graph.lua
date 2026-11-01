local M = {}
local states = {}
local namespace = vim.api.nvim_create_namespace "workspace_git_graph"
local group = vim.api.nvim_create_augroup("workspace_git_graph", { clear = true })

---@class GitGraphState
---@field buffer integer
---@field directory string
---@field root? string
---@field rows table<integer, string>
---@field busy boolean
---@field pending boolean
---@field generation integer
---@field job? vim.SystemObj
---@field preview? integer

---Return windows currently displaying the graph buffer.
---@param buffer integer
---@return integer[]
local function windows(buffer)
    return vim.fn.win_findbuf(buffer)
end

---Replace graph text without moving the selection during unchanged refreshes.
---@param state GitGraphState
---@param lines string[]
---@param rows table<integer, string>
---@param highlights table[]
local function render(state, lines, rows, highlights)
    if not vim.api.nvim_buf_is_valid(state.buffer) then
        return
    end
    local views = {}
    for _, window in ipairs(windows(state.buffer)) do
        local cursor = vim.api.nvim_win_get_cursor(window)
        views[window] = { hash = state.rows[cursor[1]], cursor = cursor }
    end
    state.rows = rows
    local existing = vim.api.nvim_buf_get_lines(state.buffer, 0, -1, false)
    if vim.deep_equal(existing, lines) then
        return
    end
    vim.bo[state.buffer].modifiable = true
    vim.api.nvim_buf_set_lines(state.buffer, 0, -1, false, lines)
    vim.bo[state.buffer].modifiable = false
    vim.api.nvim_buf_clear_namespace(state.buffer, namespace, 0, -1)
    for _, highlight in ipairs(highlights) do
        vim.api.nvim_buf_add_highlight(state.buffer, namespace, highlight[1], highlight[2], highlight[3], highlight[4])
    end
    for window, view in pairs(views) do
        local line = math.min(view.cursor[1], #lines)
        if view.hash then
            for index, hash in pairs(rows) do
                if hash == view.hash then
                    line = index
                    break
                end
            end
        end
        vim.api.nvim_win_set_cursor(window, { math.max(1, line), view.cursor[2] })
    end
end

---Decode Git's graph prefix and machine-delimited commit fields.
---@param output string
---@return string[], table<integer, string>, table[]
local function graph_lines(output)
    local lines, rows, highlights = {}, {}, {}
    for raw in output:gmatch "[^\r\n]+" do
        local graph, hash, refs, subject = raw:match "^(.-)\31([0-9a-f]+)\31(.-)\31(.*)$"
        local prefix = graph or raw
        local text = prefix
        local decorations = ""
        if hash then
            decorations = refs ~= "" and " [" .. refs .. "]" or ""
            subject = subject:gsub("[%z\1-\31\127]", " ")
            text = prefix .. subject .. decorations
            rows[#lines + 1] = hash
        end
        lines[#lines + 1] = text
        local row = #lines - 1
        for column = 1, #prefix do
            local symbol = prefix:sub(column, column)
            if symbol ~= " " then
                local color = symbol == "*" and "DiagnosticInfo"
                    or ("GitGraphLane" .. (math.floor((column - 1) / 2) % 5 + 1))
                highlights[#highlights + 1] = { color, row, column - 1, column }
            end
        end
        if #decorations > 0 then
            highlights[#highlights + 1] = { "Special", row, #prefix + #subject, #text }
        end
    end
    if #lines == 0 then
        lines = { "No commits yet" }
    end
    return lines, rows, highlights
end

---Refresh a graph from local Git history without blocking Neovim.
---@param state GitGraphState
local function refresh(state)
    if not vim.api.nvim_buf_is_valid(state.buffer) or #windows(state.buffer) == 0 then
        return
    end
    if state.busy then
        state.pending = true
        return
    end
    state.busy = true
    local generation = state.generation
    local command = { "git", "-C", state.root or state.directory }
    if state.root then
        vim.list_extend(command, {
            "log",
            "--graph",
            "--all",
            "HEAD",
            "--date-order",
            "--max-count=300",
            "--color=never",
            "--no-show-signature",
            "--no-notes",
            "--decorate=short",
            "--format=%x1f%H%x1f%D%x1f%s",
        })
    else
        vim.list_extend(command, { "rev-parse", "--show-toplevel" })
    end
    state.job = vim.system(command, { text = true }, function(result)
        vim.schedule(function()
            if state.generation ~= generation then
                return
            end
            state.busy = false
            state.job = nil
            if not vim.api.nvim_buf_is_valid(state.buffer) then
                return
            end
            if not state.root then
                if result.code == 0 then
                    state.root = vim.trim(result.stdout)
                    refresh(state)
                    return
                end
                render(state, { "Not a Git repository" }, {}, {})
            elseif result.code == 0 then
                render(state, graph_lines(result.stdout))
            else
                local message = result.stderr:match "ambiguous argument 'HEAD'" and "No commits yet"
                    or "Git history unavailable; r retries"
                render(state, { message }, {}, {})
            end
            if state.pending then
                state.pending = false
                refresh(state)
            end
        end)
    end)
end

---Show the selected commit's changes, optionally comparing with working files.
---@param window? integer
---@param options? {working_tree?: boolean}
function M.select(window, options)
    window = window or vim.api.nvim_get_current_win()
    if not vim.api.nvim_win_is_valid(window) then
        return
    end
    local state = states[vim.api.nvim_win_get_buf(window)]
    if not state or not state.root then
        return
    end
    local hash = state.rows[vim.api.nvim_win_get_cursor(window)[1]]
    if hash then
        local revision = options and options.working_tree and hash or hash .. "^!"
        vim.cmd.DiffviewOpen { args = { revision, "-C" .. state.root } }
    end
end

---Show the full selected graph entry without changing focus or Git state.
---@param window? integer
---@return integer? buffer, integer? window
function M.preview(window)
    window = window or vim.api.nvim_get_current_win()
    if not vim.api.nvim_win_is_valid(window) then
        return
    end
    local state = states[vim.api.nvim_win_get_buf(window)]
    local row = vim.api.nvim_win_get_cursor(window)[1]
    local hash = state and state.rows[row]
    if not hash then
        return
    end
    if state.preview and vim.api.nvim_win_is_valid(state.preview) then
        vim.api.nvim_win_close(state.preview, true)
    end
    local line = vim.api.nvim_buf_get_lines(state.buffer, row - 1, row, false)[1]
    local contents = { line, "", "Commit: " .. hash }
    local editor = require("framed_layout").editor()
    local position = editor and vim.fn.win_screenpos(editor) or { 2, 2 }
    local available_width = editor and vim.api.nvim_win_get_width(editor) or vim.o.columns - 2
    local available_height = editor and vim.api.nvim_win_get_height(editor) or vim.o.lines - vim.o.cmdheight - 2
    local width = math.max(1, math.min(100, available_width - 4))
    local height = 0
    for _, text in ipairs(contents) do
        height = height + math.max(1, math.ceil(vim.fn.strdisplaywidth(text) / width))
    end
    height = math.max(1, math.min(height, available_height - 3))
    local cursor_row = vim.fn.screenpos(window, row, 1).row - 1
    local top = position[1]
    local popup_row = math.max(top, math.min(cursor_row, top + available_height - height - 3))
    local buffer, popup
    require("popup_backdrop").prepare()
    vim.api.nvim_win_call(window, function()
        buffer, popup = vim.lsp.util.open_floating_preview(contents, "text", {
            border = "rounded",
            focusable = false,
            width = width,
            height = height,
            wrap = true,
            close_events = { "CursorMoved", "CursorMovedI", "BufHidden", "BufLeave", "WinLeave" },
        })
    end)
    vim.api.nvim_win_set_config(popup, {
        relative = "editor",
        anchor = "NW",
        row = popup_row,
        col = position[2] - 1 + available_width - width - 2,
        width = width,
        height = height,
    })
    vim.api.nvim_set_option_value("winblend", require("theme").popup_blend, { win = popup, scope = "local" })
    require("popup_backdrop").prepare(popup)
    state.preview = popup
    return buffer, popup
end

---Refresh one visible graph or every visible graph.
---@param window? integer
function M.refresh(window)
    if window and vim.api.nvim_win_is_valid(window) then
        local state = states[vim.api.nvim_win_get_buf(window)]
        if state then
            refresh(state)
        end
        return
    end
    for _, state in pairs(states) do
        refresh(state)
    end
end

---Populate an existing pane without creating windows or changing focus.
---@param window integer
---@param root? string Repository directory; defaults to the current working directory.
---@return integer buffer
function M.attach(window, root)
    local buffer = vim.api.nvim_win_get_buf(window)
    local state = states[buffer]
    if not state then
        buffer = vim.api.nvim_create_buf(false, true)
        state = {
            buffer = buffer,
            directory = root or vim.fn.getcwd(),
            rows = {},
            busy = false,
            pending = false,
            generation = 0,
        }
        states[buffer] = state
        vim.bo[buffer].buftype = "nofile"
        vim.bo[buffer].bufhidden = "hide"
        vim.bo[buffer].filetype = "workspace_git_graph"
        vim.bo[buffer].swapfile = false
        vim.api.nvim_buf_set_name(buffer, "GitGraph://" .. buffer)
        vim.api.nvim_buf_set_lines(buffer, 0, -1, false, { "Loading Git history..." })
        vim.bo[buffer].modifiable = false
        vim.keymap.set("n", "<CR>", M.select, { buffer = buffer, desc = "Show selected commit changes" })
        vim.keymap.set("n", "w", function()
            M.select(nil, { working_tree = true })
        end, { buffer = buffer, desc = "Compare selected commit with working tree" })
        vim.keymap.set("n", "p", M.preview, { buffer = buffer, desc = "Preview full commit and branch names" })
        vim.keymap.set("n", "<Esc>", function()
            if state.preview and vim.api.nvim_win_is_valid(state.preview) then
                vim.api.nvim_win_close(state.preview, true)
            end
        end, { buffer = buffer, desc = "Close commit preview" })
        vim.keymap.set("n", "r", function()
            refresh(state)
        end, { buffer = buffer, desc = "Refresh commit graph" })
        vim.keymap.set("n", "q", function()
            require("framed_layout").toggle_graph()
        end, { buffer = buffer, desc = "Hide commit graph" })
        vim.api.nvim_create_autocmd("BufEnter", {
            group = group,
            buffer = buffer,
            callback = function()
                refresh(state)
            end,
        })
        vim.api.nvim_create_autocmd("BufWipeout", {
            group = group,
            buffer = buffer,
            once = true,
            callback = function()
                states[buffer] = nil
                if state.job then
                    state.job:kill(15)
                end
            end,
        })
    end
    if root and root ~= state.directory then
        state.generation = state.generation + 1
        if state.job then
            state.job:kill(15)
        end
        state.directory = root
        state.root = nil
        state.job = nil
        state.busy = false
        state.pending = false
    end
    vim.api.nvim_win_set_buf(window, buffer)
    vim.wo[window].number = false
    vim.wo[window].relativenumber = false
    vim.wo[window].signcolumn = "no"
    vim.wo[window].foldcolumn = "0"
    vim.wo[window].wrap = false
    vim.wo[window].cursorline = true
    vim.wo[window].cursorlineopt = "both"
    refresh(state)
    return buffer
end

vim.api.nvim_create_autocmd("FocusGained", {
    group = group,
    callback = function()
        M.refresh()
    end,
})
local function highlight_lanes()
    for index, target in ipairs { "DiagnosticInfo", "DiagnosticHint", "DiagnosticWarn", "Special", "Identifier" } do
        vim.api.nvim_set_hl(0, "GitGraphLane" .. index, { link = target, default = true })
    end
end
vim.api.nvim_create_autocmd("ColorScheme", { group = group, callback = highlight_lanes })
highlight_lanes()

return M
