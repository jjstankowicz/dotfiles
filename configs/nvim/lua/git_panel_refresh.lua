local M = {}
local interval_ms = 1000
local timer
local job
local snapshots = {}

local function visible_state()
    local manager = require "neo-tree.sources.manager"
    local state = manager.get_state "git_status"
    if state.path and require("neo-tree.ui.renderer").window_exists(state) then
        return state
    end
end

local function poll()
    if not timer or job then
        return
    end
    local state = visible_state()
    if not state or state.loading then
        return
    end
    local path = state.path
    local active_timer = timer
    job = vim.system(
        {
            "git",
            "-C",
            path,
            "status",
            "--porcelain=v1",
            "--branch",
            "-z",
            "--untracked-files=all",
        },
        {},
        vim.schedule_wrap(function(result)
            if timer ~= active_timer then
                return
            end
            job = nil
            if result.code ~= 0 or result.stdout == snapshots[path] then
                return
            end
            local current = visible_state()
            if current ~= state or current.path ~= path or current.loading then
                return
            end
            require("neo-tree.sources.manager").navigate(current, path)
            snapshots[path] = result.stdout
        end)
    )
end

---Stop polling and release the active Git subprocess and timer.
function M.stop()
    if timer then
        timer:stop()
        timer:close()
        timer = nil
    end
    if job then
        job:kill(15)
        job = nil
    end
end

---Poll visible Git sidebars without overlapping scans or redrawing unchanged status.
function M.setup()
    M.stop()
    snapshots = {}
    timer = assert(vim.uv.new_timer())
    timer:start(interval_ms, interval_ms, vim.schedule_wrap(poll))
    local group = vim.api.nvim_create_augroup("GitPanelAutoRefresh", { clear = true })
    vim.api.nvim_create_autocmd("VimLeavePre", {
        group = group,
        callback = M.stop,
    })
end

return M
