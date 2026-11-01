-- Run with: nvim --headless -u NONE -l configs/nvim/tests/theme.lua
local root = vim.fn.fnamemodify(debug.getinfo(1, "S").source:sub(2), ":p:h:h")
vim.opt.runtimepath:prepend(root)
vim.opt.runtimepath:prepend(vim.fn.stdpath "data" .. "/lazy/vscode_modern_theme.nvim")

local original_system = vim.system
local original_uname = vim.uv.os_uname
local original_terminal_theme = vim.env.WEZTERM_THEME
local pending
local starts = 0
local reloads = 0
local theme = require "theme"

vim.uv.os_uname = function()
    return { release = "microsoft-standard-WSL2" }
end
vim.system = function(_, _, callback)
    starts = starts + 1
    if callback then
        pending = callback
        return { kill = function() end }
    end
    return {
        wait = function()
            return { code = 0, stdout = "1\r\n" }
        end,
    }
end
vim.api.nvim_create_autocmd("ColorScheme", {
    callback = function()
        reloads = reloads + 1
    end,
})

local function complete(result)
    local callback = assert(pending)
    pending = nil
    callback(result)
    assert(vim.wait(500, function()
        return vim.g.colors_name ~= nil
    end, 10))
    vim.wait(20)
end

local function check_backgrounds()
    local normal = vim.api.nvim_get_hl(0, { name = "Normal", link = false })
    local frame = {}
    for name, color in pairs(theme.palette()) do
        frame[name] = tonumber(color:sub(2), 16)
    end
    local get = function(name)
        return vim.api.nvim_get_hl(0, { name = name, link = false })
    end
    assert(get("FramedNormal").bg == frame.active)
    assert(get("FramedNormalNC").bg == frame.inactive)
    assert(get("FramedNormal").fg == normal.fg)
    assert(get("FramedNormalNC").fg == normal.fg)
    if theme.filled_borders() then
        assert(frame.active > frame.inactive and frame.inactive > frame.backdrop)
        assert(get("FramedPaneActive").fg == frame.active)
        assert(get("FramedPaneBorder").fg == frame.inactive)
    else
        assert(frame.active == frame.inactive and frame.inactive == frame.backdrop)
    end
    local original_mapping = vim.wo.winhighlight
    vim.wo.winhighlight = "Normal:FramedNormal"
    assert(require("theme").palette().backdrop == string.format("#%06x", frame.backdrop))
    assert(get("TabLineSel").bg == frame.accent and get("TabLineSel").fg == 0xffffff)
    assert(get("NvimTreeNormal").bg == frame.inactive and get("NeoTreeNormal").bg == frame.inactive)
    assert(theme.statusline().normal.a.bg == theme.palette().accent)
    vim.wo.winhighlight = original_mapping
    for _, name in ipairs {
        "FramedPaneActive",
        "FramedPaneBorder",
        "FramedBackdrop",
        "FramedBackdropEndOfBuffer",
    } do
        assert(get(name).bg == frame.backdrop, name)
    end
    for suffix, background in pairs { [""] = frame.active, NC = frame.inactive } do
        assert(get("FramedPaneTitle" .. suffix).bg == (theme.filled_borders() and background or frame.backdrop))
        for _, name in ipairs {
            "FramedEndOfBuffer",
            "FramedSignColumn",
            "FramedFoldColumn",
            "FramedLineNr",
            "FramedCursorLineNr",
        } do
            assert(get(name .. suffix).bg == background, name .. suffix)
        end
        assert(get("FramedEndOfBuffer" .. suffix).fg == background)
    end
    local cursor = get "NoiceCursor"
    assert(cursor.blend == 0 and cursor.nocombine)
end

local ok, error_message = pcall(function()
    theme.setup()
    assert(vim.g.colors_name == "vscode_modern" and vim.o.background == "light")
    assert(vim.o.winblend == theme.popup_blend)
    assert(starts == 1 and reloads == 1)
    assert(vim.api.nvim_get_hl(0, { name = "DiffAdd", link = false }).bg == 0xe4f0e6)
    check_backgrounds()
    vim.cmd "PaneStyle outline"
    check_backgrounds()
    vim.cmd "PaneStyle filled"
    check_backgrounds()

    vim.api.nvim_exec_autocmds("FocusGained", {})
    theme.refresh()
    assert(starts == 2 and reloads == 1, "overlapping refresh launched a second query")
    complete { code = 0, stdout = "1\r\n" }
    assert(reloads == 1, "unchanged theme was reloaded")

    theme.refresh()
    complete { code = 0, stdout = "0\r\n" }
    assert(vim.g.colors_name == "vscode_modern" and vim.o.background == "dark" and reloads == 2)
    assert(vim.api.nvim_get_hl(0, { name = "DiffAdd", link = false }).bg == 0x243b30)
    check_backgrounds()

    theme.refresh()
    complete { code = 1, stdout = "" }
    assert(
        vim.g.colors_name == "vscode_modern" and vim.o.background == "dark" and reloads == 2,
        "failed query changed the theme"
    )

    vim.o.background = "light"
    check_backgrounds()
    assert(vim.api.nvim_get_hl(0, { name = "DiffText", link = false }).bg == 0xb8d5f5)

    vim.uv.os_uname = function()
        return { release = "Linux" }
    end
    vim.env.WEZTERM_THEME = "OneHalfDark"
    local previous_starts = starts
    vim.api.nvim_exec_autocmds("FocusGained", {})
    assert(starts == previous_starts, "non-WSL refresh started PowerShell")
    assert(vim.g.colors_name == "vscode_modern" and vim.o.background == "dark")
    assert(vim.api.nvim_get_hl(0, { name = "DiffAdd", link = false }).bg == 0x243b30)
    check_backgrounds()
end)

theme.stop()
vim.system = original_system
vim.uv.os_uname = original_uname
vim.env.WEZTERM_THEME = original_terminal_theme
if not ok then
    io.stderr:write(tostring(error_message), "\n")
    vim.cmd "cquit"
end
print "theme checks passed"
vim.cmd "qa!"
