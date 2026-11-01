local M = {}
---@type table<integer, {buffer: integer, popups: table<integer, boolean>}>
local snapshots = {}
local commandline = false
local blank_highlights = "Normal:FramedBackdrop,NormalNC:FramedBackdrop,EndOfBuffer:FramedBackdropEndOfBuffer"

---Restore empty native backgrounds once their translucent popups have closed.
local function release()
    for window, snapshot in pairs(snapshots) do
        local valid = vim.api.nvim_win_is_valid(window)
        local visible = valid
            and commandline
            and vim.api.nvim_win_get_tabpage(window) == vim.api.nvim_get_current_tabpage()
        for popup in pairs(snapshot.popups) do
            if vim.api.nvim_win_is_valid(popup) then
                visible = true
            else
                snapshot.popups[popup] = nil
            end
        end
        if not valid then
            snapshots[window] = nil
        elseif not visible then
            vim.api.nvim_buf_set_lines(snapshot.buffer, 0, -1, false, { "" })
            vim.wo[window].winhighlight = blank_highlights
            snapshots[window] = nil
        end
    end
end

---Mirror rendered panes into the native grid used by Neovim's popup blending.
---Call before drawing a popup; an existing snapshot prevents recursive captures.
---@param popup? integer Register a popup whose close should release the snapshot.
function M.prepare(popup)
    local window = require("framed_layout").backdrop()
    if not window then
        return
    end
    local snapshot = snapshots[window]
    if not snapshot then
        local position = vim.fn.win_screenpos(window)
        local lines = {}
        local height = vim.api.nvim_win_get_height(window)
        local width = vim.api.nvim_win_get_width(window)
        for row = position[1], position[1] + height - 1 do
            local cells = {}
            for column = position[2], position[2] + width - 1 do
                -- A wide character's second cell is already represented by its first.
                if vim.fn.screenchar(row, column) ~= 0 then
                    cells[#cells + 1] = vim.fn.screenstring(row, column)
                end
            end
            lines[#lines + 1] = table.concat(cells)
        end
        local buffer = vim.api.nvim_win_get_buf(window)
        vim.bo[buffer].undolevels = -1
        snapshot = { buffer = buffer, popups = {} }
        snapshots[window] = snapshot
        vim.api.nvim_buf_set_lines(buffer, 0, -1, false, lines)
        vim.wo[window].wrap = false
        vim.wo[window].foldenable = false
        vim.wo[window].list = false
        vim.wo[window].cursorline = false
        vim.wo[window].winbar = ""
        vim.wo[window].scrolloff = 0
        vim.wo[window].sidescrolloff = 0
        vim.wo[window].winhighlight =
            "Normal:FramedPopupBackdrop,NormalNC:FramedPopupBackdrop,EndOfBuffer:FramedBackdropEndOfBuffer"
        vim.api.nvim_win_call(window, function()
            vim.fn.winrestview { topline = 1, lnum = 1, col = 0, leftcol = 0 }
        end)
    end
    if popup then
        snapshot.popups[popup] = true
    end
end

---Capture command entry before Noice draws and clean up after popup windows close.
function M.setup()
    local group = vim.api.nvim_create_augroup("PopupBackdrop", { clear = true })
    vim.api.nvim_create_autocmd("CmdlineEnter", {
        group = group,
        callback = function()
            commandline = true
            M.prepare()
        end,
    })
    vim.api.nvim_create_autocmd("CmdlineLeave", {
        group = group,
        callback = function()
            commandline = false
            vim.schedule(release)
        end,
    })
    vim.api.nvim_create_autocmd("WinClosed", {
        group = group,
        callback = function()
            vim.schedule(release)
        end,
    })
end

return M
