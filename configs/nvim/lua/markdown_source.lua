local M = {}

local server_marker = "    client.on('disconnect', function () {"
local server_patch = [[    // BEGIN markdown-source bridge
    client.on('jump_to_source', async (line, acknowledge) => {
      let jumped = false
      if (Number.isSafeInteger(line) && line >= 0) {
        try {
          jumped = await plugin.nvim.call('luaeval', [
            "require('markdown_source').jump(_A[1], _A[2])",
            [Number(bufnr), line]
          ])
        } catch (err) {
          logger.error('jump to Markdown source failed', err)
        }
      }
      if (typeof acknowledge === 'function') acknowledge(Boolean(jumped))
    })
    // END markdown-source bridge

]]

local function read(path)
    local file = assert(io.open(path, "rb"))
    local content = file:read "*a"
    file:close()
    return content
end

local function write(path, content)
    local file = assert(io.open(path, "wb"))
    assert(file:write(content))
    file:close()
end

---Jump from a zero-based preview source line to a visible Markdown buffer.
---@param buffer integer
---@param line integer
---@return boolean
function M.jump(buffer, line)
    if
        type(buffer) ~= "number"
        or type(line) ~= "number"
        or buffer % 1 ~= 0
        or line % 1 ~= 0
        or line < 0
        or not vim.api.nvim_buf_is_loaded(buffer)
        or vim.bo[buffer].filetype ~= "markdown"
    then
        return false
    end

    local windows = vim.api.nvim_tabpage_list_wins(0)
    -- Prefer the current tab, then a tab already displaying this document.
    for _, window in ipairs(vim.api.nvim_list_wins()) do
        if not vim.tbl_contains(windows, window) then
            table.insert(windows, window)
        end
    end
    for _, window in ipairs(windows) do
        if
            vim.api.nvim_win_get_buf(window) == buffer
            and (vim.api.nvim_win_get_config(window).relative == "" or require("framed_layout").is_editor(window))
        then
            vim.api.nvim_set_current_win(window)
            local row = math.min(line + 1, vim.api.nvim_buf_line_count(buffer))
            vim.api.nvim_win_set_cursor(window, { row, 0 })
            vim.cmd "normal! zz"
            return true
        end
    end
    return false
end

---Apply the tracked bridge to the plugin's disk-loaded server and browser page.
---@param plugin_dir string
function M.setup(plugin_dir)
    local server_path = plugin_dir .. "/app/server.js"
    local html_path = plugin_dir .. "/app/out/index.html"
    local script_path = vim.fn.stdpath "config" .. "/markdown-preview/source-navigation.js"
    local ok, err = pcall(function()
        local server =
            read(server_path):gsub("    // BEGIN markdown%-source bridge\n.-    // END markdown%-source bridge\n\n", "")
        local html = read(html_path):gsub('<script id="markdown%-source%-bridge">.-</script>', "")
        local script = read(script_path)
        local start = assert(server:find(server_marker, 1, true), "Preview server layout changed")
        local body = assert(html:find("</body>", 1, true), "Preview HTML layout changed")
        local patched_server = server:sub(1, start - 1) .. server_patch .. server:sub(start)
        local patched_html = html:sub(1, body - 1)
            .. '<script id="markdown-source-bridge">'
            .. script
            .. "</script>"
            .. html:sub(body)
        if read(server_path) ~= patched_server then
            write(server_path, patched_server)
        end
        if read(html_path) ~= patched_html then
            write(html_path, patched_html)
        end
    end)
    if not ok then
        vim.notify("Markdown source navigation unavailable: " .. tostring(err), vim.log.levels.WARN)
    end
end

return M
