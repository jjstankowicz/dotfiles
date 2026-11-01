local M = {}
---@type table<integer, integer>
local sources = {}
---@type table<integer, {source: integer, editor: integer, outline: integer}>
local buffers = {}
local pending = false

---Jump to the selected symbol in its editor without replacing another pane.
---@param focus boolean Whether to focus the editor after jumping.
local function select(focus)
    local window = vim.api.nvim_get_current_win()
    local editor = sources[window]
    if not editor or not vim.api.nvim_win_is_valid(editor) then
        return
    end
    local index = vim.api.nvim_win_get_cursor(window)[1]
    vim.api.nvim_win_call(editor, function()
        require("aerial").select { index = index, jump = false }
    end)
    if focus then
        vim.api.nvim_set_current_win(editor)
    end
end

---Configure the outline backend while leaving window ownership to the workspace.
---@param options table
function M.setup(options)
    require("aerial").setup(options)
    local group = vim.api.nvim_create_augroup("workspace_code_outline", { clear = true })
    vim.api.nvim_create_autocmd({ "BufWinEnter", "FileType", "LspAttach" }, {
        group = group,
        callback = function()
            if pending then
                return
            end
            pending = true
            vim.schedule(function()
                pending = false
                M.update()
            end)
        end,
    })
end

---Populate an existing outline pane for the buffer currently shown in its editor.
---@param window integer
---@param editor integer
---@return integer buffer
function M.attach(window, editor)
    sources[window] = editor
    -- Aerial normally chooses a width once per window; the workspace owns geometry.
    vim.w[window].aerial_set_width = true
    local source_buffer = vim.api.nvim_win_get_buf(editor)
    local previous = buffers[window]
    if
        not previous
        or previous.source ~= source_buffer
        or previous.editor ~= editor
        or previous.outline ~= vim.api.nvim_win_get_buf(window)
    then
        require("aerial").open_in_win(window, editor)
        buffers[window] = { source = source_buffer, editor = editor, outline = vim.api.nvim_win_get_buf(window) }
    end
    local buffer = vim.api.nvim_win_get_buf(window)
    vim.bo[buffer].bufhidden = "hide"
    vim.wo[window].cursorline = true
    vim.wo[window].cursorlineopt = "both"
    return buffer
end

---Refresh the outline associated with an existing pane and source editor.
---@param window integer
---@param editor integer
---@return integer buffer
function M.refresh(window, editor)
    return M.attach(window, editor)
end

---Follow source-buffer changes without moving focus or opening new windows.
---@param editor? integer Restrict updates to one source editor.
function M.update(editor)
    for window, source in pairs(sources) do
        if not vim.api.nvim_win_is_valid(window) or not vim.api.nvim_win_is_valid(source) then
            sources[window] = nil
            buffers[window] = nil
        elseif not editor or editor == source then
            M.attach(window, source)
        end
    end
end

---Return the plugin options shared by every workspace outline.
---@return table
function M.options()
    return {
        backends = { "treesitter", "lsp", "markdown", "man" },
        attach_mode = "window",
        close_automatic_events = {},
        ignore = { wintypes = false },
        layout = { resize_to_content = false, preserve_equality = false },
        float = {
            override = function(config, editor)
                for window, source in pairs(sources) do
                    if source == editor and vim.api.nvim_win_is_valid(window) then
                        local geometry = vim.w[window].framed_geometry
                        if geometry then
                            -- Aerial resizes floats after symbol updates even with resize_to_content disabled.
                            return vim.tbl_extend("force", config, geometry)
                        end
                    end
                end
                return config
            end,
        },
        highlight_mode = "last",
        highlight_on_jump = false,
        show_guides = true,
        manage_folds = false,
        link_tree_to_folds = false,
        keymaps = {
            ["<CR>"] = function()
                select(true)
            end,
            ["<2-LeftMouse>"] = function()
                select(true)
            end,
            ["p"] = function()
                select(false)
            end,
            ["<C-v>"] = false,
            ["<C-s>"] = false,
            ["<C-j>"] = false,
            ["<C-k>"] = false,
            ["q"] = function()
                require("framed_layout").toggle_outline()
            end,
        },
    }
end

return M
