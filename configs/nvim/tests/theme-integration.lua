-- Check both Modern themes against the actual buffer bar and status bar plugins.
-- Run with: nvim --headless -n -c "luafile configs/nvim/tests/theme-integration.lua"
vim.defer_fn(function()
    local ok, err = xpcall(function()
        local get = function(name)
            return vim.api.nvim_get_hl(0, { name = name, link = false })
        end
        for _, background in ipairs { "dark", "light", "dark", "light" } do
            vim.o.background = background
            vim.cmd.colorscheme "vscode_modern"
            local colors = require("theme").palette()
            local accent = tonumber(colors.accent:sub(2), 16)
            assert(get("BufferLineBufferSelected").bg == accent, "Selected buffer lost its blue background")
            assert(get("BufferLineBufferSelected").fg == 0xffffff, "Selected buffer lost its text contrast")
            assert(get("lualine_a_normal").bg == accent, "Status bar lost its blue accent")
            assert(get("BufferLineFill").bg == tonumber(colors.backdrop:sub(2), 16))
            assert(get("ReadingIndent").fg == tonumber(colors.indent:sub(2), 16))
            assert(get("CursorLine").bg == tonumber(colors.selection:sub(2), 16))
            for _, group in ipairs { "RenderMarkdownCode", "RenderMarkdownCodeInline" } do
                assert(get(group).bg == tonumber(colors.code:sub(2), 16), "Markdown code lost its theme background")
                assert(not get(group).reverse, "Markdown code background is reversed")
            end
            local lazygit = vim.fn.stdpath "config" .. "/../lazygit/"
            local file = background == "dark" and "dark.yml" or "config.yml"
            local settings = table.concat(vim.fn.readfile(lazygit .. file), "\n")
            for _, key in ipairs { "accent", "border", "selection", "foreground" } do
                assert(settings:find(colors[key], 1, true), "Lazygit differs from the " .. key .. " palette")
            end
        end
        print "PASS: Modern light/dark switching, buffer tabs, status bar, guides, selection, and Lazygit palettes"
    end, debug.traceback)
    if not ok then
        print(err)
        vim.cmd "cquit"
    else
        vim.cmd "qa!"
    end
end, 1500)
