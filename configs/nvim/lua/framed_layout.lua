local M = {}
local states = {}
local updating = false
local minimum_sidebar = 8
local minimum_editor = 20
local drag
local native_offsets
local editor_winbar = "%{%v:lua.require'buffers'.render()%}"
local pane_roles = { "files", "outline", "editor", "git", "graph" }

local function valid(window)
    return window and vim.api.nvim_win_is_valid(window)
end

local function current_state()
    return states[vim.api.nvim_get_current_tabpage()]
end

local function remember_focus(state, window)
    if state and state.active then
        if window == state.files then
            state.left_focus = "files"
        elseif window == state.outline then
            state.left_focus = "outline"
        elseif window == state.git then
            state.right_focus = "git"
        elseif window == state.graph then
            state.right_focus = "graph"
        end
    end
end

---Return the editor belonging to the current framed workspace.
---@return integer?
function M.editor()
    local state = current_state()
    return state and valid(state.editor) and state.editor or nil
end

---Return the native background window beneath the framed workspace.
---@return integer?
function M.backdrop()
    local state = current_state()
    return state and state.active and valid(state.backdrop) and state.backdrop or nil
end

---Return the visible commit graph belonging to the current workspace.
---@return integer?
function M.graph()
    local state = current_state()
    return state and valid(state.graph) and state.graph or nil
end

---Return the visible code outline belonging to the current workspace.
---@return integer?
function M.outline()
    local state = current_state()
    return state and valid(state.outline) and state.outline or nil
end

---Identify an editing window even when it is a framed float.
---@param window integer
---@return boolean
function M.is_editor(window)
    return valid(window) and vim.w[window].framed_pane == "editor"
end

---List workspace panes without including popups or the background window.
---@return integer[]
function M.panes()
    local state = current_state()
    if state and state.active then
        local windows = {}
        for _, role in ipairs(pane_roles) do
            if valid(state[role]) then
                table.insert(windows, state[role])
            end
        end
        return windows
    end
    return vim.tbl_filter(function(window)
        return vim.api.nvim_win_get_config(window).relative == ""
    end, vim.api.nvim_tabpage_list_wins(0))
end

local function border_highlight(window, owner)
    local active = vim.api.nvim_get_current_win() == (owner or window)
    local highlight = active and "FramedPaneActive" or "FramedPaneBorder"
    local suffix = active and "" or "NC"
    local normal = owner and "FramedPaneTitle" .. suffix or (active and "FramedNormal" or "FramedNormalNC")
    vim.wo[window].winhighlight = table.concat({
        "Normal:" .. normal,
        "NormalNC:" .. normal,
        "NormalFloat:" .. normal,
        "SignColumn:FramedSignColumn" .. suffix,
        "FoldColumn:FramedFoldColumn" .. suffix,
        "LineNr:FramedLineNr" .. suffix,
        "CursorLineNr:FramedCursorLineNr" .. suffix,
        "EndOfBuffer:FramedEndOfBuffer" .. suffix,
        "WinBar:FramedWinBar" .. suffix,
        "WinBarNC:FramedWinBar" .. suffix,
        "FloatTitle:FramedPaneTitle" .. suffix,
        "FloatBorder:" .. highlight,
    }, ",")
end

local function widths(state)
    local roles = {}
    for _, role in ipairs { "files", "git" } do
        if valid(state[role]) then
            table.insert(roles, role)
        end
    end
    local available = math.max(#roles + 1, vim.o.columns - 2 - 3 * #roles)
    local editor = math.min(minimum_editor, math.max(1, available - #roles))
    local budget = available - editor
    local minimum = #roles > 0 and math.max(1, math.min(minimum_sidebar, math.floor(budget / #roles))) or 1
    local result = { files = 0, git = 0 }
    local total = 0
    for _, role in ipairs(roles) do
        result[role] = math.max(minimum, math.min(state.widths[role], budget))
        total = total + result[role]
    end
    while total > budget do
        local changed = false
        for _, role in ipairs(roles) do
            if result[role] > minimum and total > budget then
                result[role] = result[role] - 1
                total = total - 1
                changed = true
            end
        end
        if not changed then
            break
        end
    end
    return result
end

local function close_headers(state)
    for _, window in pairs(state.headers or {}) do
        if valid(window) then
            vim.api.nvim_win_close(window, true)
        end
    end
    state.headers = {}
end

local function configure(state, role, column, width, height, title, row)
    row = row or 0
    local window = state[role]
    local header = state.headers[role]
    if not valid(window) then
        if valid(header) then
            vim.api.nvim_win_close(header, true)
        end
        state.headers[role] = nil
        return
    end
    local points = require("theme").filled_borders()
            and { 0x1fbee, 0x2584, 0x1fbed, 0x258c, 0x1fbef, 0x2580, 0x1fbec, 0x2590 }
        or { 0x256d, 0x2500, 0x256e, 0x2502, 0x256f, 0x2500, 0x2570, 0x2502 }
    local border = vim.tbl_map(vim.fn.nr2char, points)
    local header_config = {
        relative = "editor",
        row = row,
        col = column,
        width = width,
        height = 1,
        border = { border[1], border[2], border[3], border[4], "", "", "", border[8] },
        focusable = false,
        mouse = false,
        zindex = 20,
    }
    if not valid(header) then
        local buffer = vim.api.nvim_create_buf(false, true)
        vim.bo[buffer].bufhidden = "wipe"
        vim.bo[buffer].filetype = "framed-header"
        header = vim.api.nvim_open_win(buffer, false, header_config)
        state.headers[role] = header
        vim.wo[header].number = false
        vim.wo[header].relativenumber = false
        vim.wo[header].signcolumn = "no"
        vim.wo[header].statusline = " "
        vim.wo[header].winbar = ""
        vim.wo[header].wrap = false
        vim.wo[header].winblend = 0
    else
        vim.api.nvim_win_set_config(header, header_config)
    end
    local label = title:sub(1, width)
    label = string.rep(" ", math.floor((width - #label) / 2)) .. label
    local buffer = vim.api.nvim_win_get_buf(header)
    if vim.api.nvim_buf_get_lines(buffer, 0, 1, false)[1] ~= label then
        vim.api.nvim_buf_set_lines(buffer, 0, -1, false, { label })
    end
    border_highlight(header, window)
    vim.w[window].framed_geometry = { row = row + 2, col = column, width = width, height = height }
    vim.api.nvim_win_set_config(window, {
        relative = "editor",
        row = row + 2,
        col = column,
        width = width,
        height = height,
        border = { "", "", "", border[4], border[5], border[6], border[7], border[8] },
        title = "",
        zindex = 20,
    })
    vim.wo[window].winblend = 0
    vim.wo[window].winbar = title == "Editor" and editor_winbar or ""
    border_highlight(window)
end

local function close_panel(state, role)
    if valid(state[role]) then
        state[role .. "_buffer"] = vim.api.nvim_win_get_buf(state[role])
        if vim.api.nvim_get_current_win() == state[role] and valid(state.editor) then
            vim.api.nvim_set_current_win(state.editor)
        end
        vim.api.nvim_win_close(state[role], true)
    end
    state[role] = nil
    if state.headers and valid(state.headers[role]) then
        vim.api.nvim_win_close(state.headers[role], true)
    end
    if state.headers then
        state.headers[role] = nil
    end
end

local function open_panel(state, role)
    if valid(state[role]) then
        return
    end
    local buffer = state[role .. "_buffer"]
    local placeholder = false
    if not buffer or not vim.api.nvim_buf_is_valid(buffer) then
        buffer = vim.api.nvim_create_buf(false, true)
        vim.bo[buffer].bufhidden = "hide"
        placeholder = true
    end
    local window = vim.api.nvim_open_win(buffer, false, {
        relative = "editor",
        row = 2,
        col = 0,
        width = 1,
        height = 1,
        zindex = 20,
    })
    state[role] = window
    vim.w[window].framed_pane = role
    vim.wo[window].number = false
    vim.wo[window].relativenumber = false
    vim.wo[window].signcolumn = "no"
    vim.wo[window].wrap = false
    if role == "graph" then
        local file = vim.api.nvim_buf_get_name(vim.api.nvim_win_get_buf(state.editor))
        local root = vim.fs.root(file ~= "" and file or vim.fn.getcwd(), ".git")
        state.graph_buffer = require("git_graph").attach(window, root)
    else
        state.outline_buffer = require("code_outline").attach(window, state.editor)
    end
    if placeholder and state[role .. "_buffer"] ~= buffer and vim.api.nvim_buf_is_valid(buffer) then
        vim.api.nvim_buf_delete(buffer, { force = true })
    end
end

---Resize the visible frames without altering buffers, cursors, or focus.
function M.resize()
    local state = current_state()
    if updating or not state or not state.active or not valid(state.editor) then
        if not updating then
            vim.o.showtabline = 2
            if state then
                close_panel(state, "graph")
                close_panel(state, "outline")
                close_headers(state)
            end
            for _, window in ipairs(vim.api.nvim_tabpage_list_wins(0)) do
                if vim.wo[window].winbar == editor_winbar then
                    vim.wo[window].winbar = ""
                end
            end
        end
        return
    end
    updating = true
    local ok, err = pcall(function()
        local columns = vim.o.columns
        local sidebar = widths(state)
        vim.o.showtabline = 0
        state.headers = state.headers or {}
        local height = math.max(1, vim.o.lines - vim.o.cmdheight - 4)
        local left = valid(state.files) and sidebar.files + 3 or 0
        local right = valid(state.git) and sidebar.git + 3 or 0
        if state.outline_enabled and valid(state.files) and height >= 15 then
            open_panel(state, "outline")
            local total = height + 3
            local outline_height = math.max(7, math.min(state.outline_height or math.floor(total * 0.45), total - 8))
            local file_height = total - outline_height - 1
            configure(state, "files", 0, sidebar.files, file_height - 3, "Files")
            configure(state, "outline", 0, sidebar.files, outline_height - 3, "Outline", file_height + 1)
        else
            close_panel(state, "outline")
            configure(state, "files", 0, sidebar.files, height, "Files")
        end
        configure(state, "editor", left, math.max(1, columns - left - right - 2), height, "Editor")
        local graph_visible = state.graph_enabled and valid(state.git) and height >= 15
        if graph_visible then
            open_panel(state, "graph")
            local total = height + 3
            local graph_height = math.max(7, math.min(state.graph_height or math.floor(total * 0.45), total - 8))
            local git_height = total - graph_height - 1
            local column = columns - sidebar.git - 2
            configure(state, "git", column, sidebar.git, git_height - 3, "Git")
            configure(state, "graph", column, sidebar.git, graph_height - 3, "Git Graph", git_height + 1)
        else
            close_panel(state, "graph")
            configure(state, "git", columns - sidebar.git - 2, sidebar.git, height, "Git")
        end
        state.rendered = {
            files = sidebar.files,
            git = sidebar.git,
            editor = vim.api.nvim_win_get_width(state.editor),
        }
        vim.cmd "redrawstatus"
    end)
    updating = false
    if not ok then
        error(err)
    end
end

---Frame the existing Files, Editor, and Git windows while preserving sidebar state.
---@param editor integer
---@param files integer?
---@param git integer?
function M.attach(editor, files, git)
    if vim.fn.has "nvim-0.11" ~= 1 then
        return
    end
    local tab = vim.api.nvim_get_current_tabpage()
    local state = states[tab] or {}
    state.widths = state.widths or { files = 30, git = 30 }
    if state.graph_enabled == nil then
        state.graph_enabled = vim.g.workspace_git_graph == true
    end
    if state.outline_enabled == nil then
        state.outline_enabled = vim.g.workspace_code_outline == true
    end
    state.editor, state.files, state.git = editor, files, git
    if not valid(state.backdrop) or state.backdrop == editor then
        local buffer = vim.api.nvim_create_buf(false, true)
        vim.bo[buffer].bufhidden = "wipe"
        vim.bo[buffer].filetype = "framed-backdrop"
        state.backdrop = vim.api.nvim_open_win(buffer, false, { split = "below", win = editor, height = 1 })
        vim.wo[state.backdrop].number = false
        vim.wo[state.backdrop].relativenumber = false
        vim.wo[state.backdrop].signcolumn = "no"
        vim.wo[state.backdrop].statusline = " "
        vim.wo[state.backdrop].winhighlight =
            "Normal:FramedBackdrop,NormalNC:FramedBackdrop,EndOfBuffer:FramedBackdropEndOfBuffer"
    end
    states[tab] = state
    state.active = true
    for role, window in pairs { editor = editor, files = files, git = git } do
        if valid(window) then
            vim.w[window].framed_pane = role
        end
    end
    M.resize()
    vim.api.nvim_set_current_win(editor)
end

local function adjust_requested_width(state, delta)
    local window = vim.api.nvim_get_current_win()
    local role = (window == state.files or window == state.outline) and "files"
        or (window == state.git or window == state.graph) and "git"
        or nil
    if window == state.editor then
        role = valid(state.git) and "git" or valid(state.files) and "files" or nil
        delta = -delta
    end
    if role then
        state.widths[role] = math.max(minimum_sidebar, vim.api.nvim_win_get_width(state[role]) + delta)
    end
end

---Resize the selected pane while preserving the workspace and native split controls.
---@param delta integer Width change in columns; zero equalizes the visible panes.
function M.adjust_width(delta)
    local state = current_state()
    if not state or not state.active then
        vim.cmd(delta == 0 and "wincmd =" or math.abs(delta) .. "wincmd " .. (delta > 0 and ">" or "<"))
        return
    end
    if delta == 0 then
        local count = 1 + (valid(state.files) and 1 or 0) + (valid(state.git) and 1 or 0)
        local width = math.max(minimum_sidebar, math.floor((vim.o.columns - 2 - 3 * (count - 1)) / count))
        state.widths.files, state.widths.git = width, width
    else
        adjust_requested_width(state, delta)
    end
    M.resize()
end

---Move between framed panes, retaining native navigation in other tabs/layouts.
---@param direction "left"|"right"|"up"|"down"
---@param wrap? boolean Wrap at the edges of the framed workspace.
function M.focus(direction, wrap)
    local state = current_state()
    if not state or not state.active then
        local command = { left = "h", right = "l", up = "k", down = "j" }
        vim.cmd("wincmd " .. command[direction])
        return
    end
    local current = vim.api.nvim_get_current_win()
    remember_focus(state, current)
    local target
    if direction == "up" or direction == "down" then
        target = direction == "up" and current == state.graph and state.git
            or direction == "down" and current == state.git and state.graph
            or direction == "up" and current == state.outline and state.files
            or direction == "down" and current == state.files and state.outline
        if wrap and not valid(target) then
            target = current == state.files and state.outline
                or current == state.outline and state.files
                or current == state.git and state.graph
                or current == state.graph and state.git
        end
    elseif current == state.editor then
        if direction == "left" then
            target = valid(state[state.left_focus or "files"]) and state[state.left_focus or "files"] or state.files
        else
            target = valid(state[state.right_focus or "git"]) and state[state.right_focus or "git"] or state.git
        end
    elseif (current == state.files or current == state.outline) and direction == "right" then
        target = state.editor
    elseif (current == state.git or current == state.graph) and direction == "left" then
        target = state.editor
    end
    if wrap and (direction == "left" or direction == "right") and not valid(target) then
        local upper, lower
        if direction == "right" then
            upper, lower = state.files, state.outline
        else
            upper, lower = state.git, state.graph
        end
        target = (current == state.outline or current == state.graph) and valid(lower) and lower or upper
        if not valid(target) then
            target = state.editor
        end
    end
    if valid(target) then
        remember_focus(state, target)
        vim.api.nvim_set_current_win(target)
    end
end

---Toggle the lower-right commit graph without replacing the Git status pane.
function M.toggle_graph()
    local state = current_state()
    if not state or not state.active or not valid(state.git) then
        vim.notify("Show the Git sidebar with Space-gs before opening its graph", vim.log.levels.INFO)
        return
    end
    state.graph_enabled = not state.graph_enabled
    M.resize()
end

---Toggle the lower-left outline without replacing the file explorer.
function M.toggle_outline()
    local state = current_state()
    if not state or not state.active or not valid(state.files) then
        vim.notify("Show the Files sidebar before opening its outline", vim.log.levels.INFO)
        return
    end
    state.outline_enabled = not state.outline_enabled
    M.resize()
end

---Open a sidebar file in the framed editor using normal modified-buffer checks.
---@param path string
---@param buffer integer?
---@return boolean
function M.open_file(path, buffer)
    local state = current_state()
    if not state or not state.active or not valid(state.editor) then
        return false
    end
    vim.api.nvim_set_current_win(state.editor)
    if not buffer or buffer < 1 or not vim.api.nvim_buf_is_valid(buffer) then
        buffer = vim.fn.bufadd(path)
    end
    vim.cmd.buffer { args = { tostring(buffer) } }
    vim.bo[buffer].buflisted = true
    return true
end

---Restore native splits before commands that require a split-capable editor.
function M.native()
    local state = current_state()
    if not state or not state.active then
        return
    end
    if not valid(state.editor) then
        state.active = false
        return
    end
    local current = vim.api.nvim_get_current_win()
    local sidebar = widths(state)
    state.active = false
    close_panel(state, "graph")
    close_panel(state, "outline")
    close_headers(state)
    vim.wo[state.editor].winbar = ""
    vim.o.showtabline = 2
    vim.api.nvim_win_set_config(state.editor, { relative = "", split = "right", win = state.backdrop })
    if valid(state.files) then
        vim.api.nvim_win_set_config(state.files, { relative = "", split = "left", win = state.editor })
        vim.api.nvim_win_set_width(state.files, sidebar.files)
    end
    if valid(state.git) then
        vim.api.nvim_win_set_config(state.git, { relative = "", split = "right", win = state.editor })
        vim.api.nvim_win_set_width(state.git, sidebar.git)
    end
    if valid(state.backdrop) then
        vim.api.nvim_win_close(state.backdrop, true)
    end
    for _, role in ipairs { "files", "editor", "git" } do
        if valid(state[role]) then
            vim.wo[state[role]].winhighlight = ""
        end
    end
    if valid(current) then
        vim.api.nvim_set_current_win(current)
    end
end

---Toggle the file sidebar without asking a floating editor to create a split.
function M.toggle_files()
    local state = current_state()
    local api = require "nvim-tree.api"
    if not state or not state.active then
        api.tree.toggle()
        return
    end
    local editor = state.editor
    if api.tree.is_visible() then
        api.tree.close()
    else
        M.native()
        vim.api.nvim_set_current_win(editor)
        api.tree.open { focus = false }
        M.attach(editor, require("nvim-tree.view").get_winnr(), state.git)
    end
    vim.api.nvim_set_current_win(editor)
    M.resize()
end

---Toggle the Git sidebar and resize the remaining framed panes.
function M.toggle_git()
    local state = current_state()
    local command = require "neo-tree.command"
    if not state or not state.active then
        command.execute { source = "git_status", position = "right", action = "toggle" }
        return
    end
    local editor = state.editor
    if valid(state.git) then
        command.execute { source = "git_status", action = "close" }
    else
        M.native()
        vim.api.nvim_set_current_win(editor)
        command.execute { source = "git_status", position = "right", action = "show" }
        M.attach(editor, state.files, require("neo-tree.sources.manager").get_state("git_status").winid)
    end
    vim.api.nvim_set_current_win(editor)
    M.resize()
end

local function mouse_resize(key)
    local state = current_state()
    local position = vim.fn.getmousepos()
    local column, row = position.screencol - 1, position.screenrow - 1
    if key == "<LeftMouse>" then
        drag = nil
        if not state or not state.active then
            return key
        end
        for _, window in ipairs(vim.api.nvim_tabpage_list_wins(0)) do
            local config = vim.api.nvim_win_get_config(window)
            if config.relative ~= "" and (config.zindex or 50) > 20 then
                local screen = vim.fn.win_screenpos(window)
                local border = config.border and #config.border > 0 and 1 or 0
                local top, left = screen[1] - 1 - border, screen[2] - 1 - border
                if
                    row >= top
                    and row < top + config.height + 2 * border
                    and column >= left
                    and column < left + config.width + 2 * border
                then
                    return key
                end
            end
        end
        if
            position.winid ~= 0
            and position.winid ~= state.editor
            and position.winid ~= state.files
            and position.winid ~= state.git
            and position.winid ~= state.graph
            and position.winid ~= state.outline
            and position.winid ~= state.backdrop
        then
            return key
        end
        local editor = vim.api.nvim_win_get_config(state.editor)
        if row < editor.row or row > editor.row + editor.height + 1 then
            return key
        end
        for _, role in ipairs { "outline", "graph" } do
            if valid(state[role]) then
                local panel = vim.api.nvim_win_get_config(state[role])
                local edge = panel.row - 3
                if
                    column >= panel.col
                    and column <= panel.col + panel.width + 1
                    and row >= edge
                    and row <= edge + 1
                then
                    drag = {
                        state = state,
                        role = role .. "_height",
                        row = row,
                        height = panel.height + 3,
                    }
                    return ""
                end
            end
        end
        for _, role in ipairs { "files", "git" } do
            if valid(state[role]) then
                local config = vim.api.nvim_win_get_config(state[role])
                local edge = role == "files" and config.col + config.width + 1 or config.col
                local lower, upper = role == "files" and edge or edge - 2, role == "files" and edge + 2 or edge
                if column >= lower and column <= upper then
                    drag = {
                        state = state,
                        role = role,
                        column = column,
                        width = config.width,
                        sign = role == "files" and 1 or -1,
                    }
                    return ""
                end
            end
        end
        return key
    end
    if not drag then
        return key
    end
    local captured = drag
    if captured.role == "graph_height" or captured.role == "outline_height" then
        local height = captured.height - row + captured.row
        if key == "<LeftRelease>" then
            drag = nil
        end
        vim.schedule(function()
            if current_state() == captured.state and captured.state.active then
                captured.state[captured.role] = height
                M.resize()
            end
        end)
        return ""
    end
    local width = math.max(minimum_sidebar, captured.width + captured.sign * (column - captured.column))
    if key == "<LeftRelease>" then
        drag = nil
    end
    -- Expression mappings run under textlock; geometry changes belong on the next event-loop turn.
    vim.schedule(function()
        if current_state() == captured.state and captured.state.active then
            captured.state.widths[captured.role] = width
            M.resize()
        end
    end)
    return ""
end

---Install layout lifecycle hooks and align the buffer bar with the framed editor.
function M.setup()
    local group = vim.api.nvim_create_augroup("FramedWorkspace", { clear = true })
    vim.api.nvim_create_autocmd({ "VimResized", "WinEnter", "TabEnter", "WinClosed", "ColorScheme" }, {
        group = group,
        callback = function(event)
            if event.event == "WinEnter" then
                remember_focus(current_state(), vim.api.nvim_get_current_win())
            end
            if event.event == "WinClosed" then
                local state = current_state()
                local closed = tonumber(event.match)
                local tracked = state and closed == state.backdrop
                if state then
                    for _, role in ipairs(pane_roles) do
                        tracked = tracked or closed == state[role] or closed == (state.headers or {})[role]
                    end
                end
                if not tracked then
                    return
                end
            end
            if not updating then
                vim.schedule(M.resize)
            end
        end,
    })
    vim.api.nvim_create_autocmd("TabClosed", {
        group = group,
        callback = function()
            for tab in pairs(states) do
                if not vim.api.nvim_tabpage_is_valid(tab) then
                    states[tab] = nil
                end
            end
        end,
    })
    vim.api.nvim_create_autocmd("WinResized", {
        group = group,
        callback = function()
            local state = current_state()
            if updating or not state or not state.active or not state.rendered or not valid(state.editor) then
                return
            end
            local changed = false
            for _, role in ipairs { "files", "git" } do
                if valid(state[role]) then
                    local width = vim.api.nvim_win_get_width(state[role])
                    if width ~= state.rendered[role] then
                        state.widths[role] = math.max(minimum_sidebar, width)
                        changed = true
                    end
                end
            end
            local editor = vim.api.nvim_win_get_width(state.editor)
            if not changed and editor ~= state.rendered.editor then
                local role = valid(state.git) and "git" or valid(state.files) and "files" or nil
                if role then
                    state.widths[role] =
                        math.max(minimum_sidebar, state.rendered[role] - editor + state.rendered.editor)
                    changed = true
                end
            end
            if changed then
                M.resize()
            end
        end,
    })
    vim.api.nvim_create_autocmd("CmdlineLeave", {
        group = group,
        callback = function()
            if vim.v.event.cmdtype ~= ":" or vim.v.event.abort then
                return
            end
            local ok, command = pcall(vim.api.nvim_parse_cmd, vim.fn.getcmdline(), {})
            local state = current_state()
            if
                ok
                and state
                and state.active
                and command.cmd == "resize"
                and command.mods.vertical
                and #command.range == 0
            then
                local argument = command.args[1] or ""
                local width = tonumber(argument)
                if width then
                    local current = vim.api.nvim_win_get_width(0)
                    local relative = argument:match "^[+-]" ~= nil
                    local delta = relative and width or width - current
                    if delta ~= 0 then
                        adjust_requested_width(state, delta)
                        vim.schedule(M.resize)
                    end
                end
                return
            end
            if
                ok and vim.tbl_contains({ "split", "vsplit", "new", "vnew", "Gdiffsplit", "Gvdiffsplit" }, command.cmd)
            then
                M.native()
            end
        end,
    })
    for _, key in ipairs { "s", "v" } do
        vim.keymap.set("n", "<C-w>" .. key, function()
            M.native()
            vim.cmd(key == "s" and "split" or "vsplit")
        end, { desc = "Split editing window" })
    end
    for key, direction in pairs { j = "down", k = "up" } do
        vim.keymap.set("n", "<C-w>" .. key, function()
            M.focus(direction)
        end, { desc = "Focus pane " .. direction })
    end
    for key, sign in pairs { [">"] = 1, ["<"] = -1, ["="] = 0 } do
        vim.keymap.set("n", "<C-w>" .. key, function()
            M.adjust_width(sign * vim.v.count1)
        end, { desc = sign == 0 and "Equalize pane widths" or "Resize pane width" })
    end
    for _, key in ipairs { "<LeftMouse>", "<LeftDrag>", "<LeftRelease>" } do
        vim.keymap.set({ "n", "x", "i" }, key, function()
            return mouse_resize(key)
        end, { expr = true, desc = "Resize framed pane borders" })
    end
    local offsets = require "bufferline.offset"
    native_offsets = native_offsets or offsets.get
    -- Bufferline v4.9.1 uses screen width; the editor winbar needs window-width truncation.
    offsets.get = function()
        local state = current_state()
        if not state or not state.active or not valid(state.editor) then
            return native_offsets()
        end
        return {
            total_size = vim.o.columns - vim.api.nvim_win_get_width(state.editor),
            left_size = 0,
            right_size = 0,
            left = "",
            right = "",
        }
    end
end

return M
