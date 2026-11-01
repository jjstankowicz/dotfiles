local M = { popup_blend = 5 }

local palettes = {
    light = {
        backdrop = "#ebebeb",
        inactive = "#f3f3f3",
        active = "#ffffff",
        border = "#b8b8b8",
        focused = "#616161",
        accent = "#005fb8",
        selection = "#cce5ff",
        indent = "#d6d6d6",
        code = "#f3f3f3",
        add = "#e4f0e6",
        delete = "#f7e5e7",
        removed = "#a1260d",
        change = "#e5effa",
        text = "#b8d5f5",
    },
    dark = {
        backdrop = "#181818",
        inactive = "#242424",
        active = "#2b2b2b",
        border = "#515151",
        focused = "#b0b0b0",
        accent = "#0078d4",
        selection = "#264f78",
        indent = "#404040",
        code = "#292929",
        add = "#243b30",
        delete = "#392c32",
        removed = "#f14c4c",
        change = "#25364a",
        text = "#3b5675",
    },
}

---Whether workspace frames use filled two-color edges.
---@return boolean
function M.filled_borders()
    return vim.g.framed_border_style ~= "outline"
end

local function lighten(color, amount)
    local channels = {}
    for channel in color:gmatch "%x%x" do
        local value = tonumber(channel, 16)
        channels[#channels + 1] = math.floor(value + (255 - value) * amount + 0.5)
    end
    return string.format("#%02x%02x%02x", unpack(channels))
end

---Return the shared pane and bar palette for the current colorscheme.
---@return table<string, string>
function M.palette()
    local light = vim.o.background == "light"
    -- Read the global colors rather than the framed window's remapped Normal.
    local normal = vim.fn.hlID "Normal"
    local foreground = vim.fn.synIDattr(normal, "fg", "gui")
    local background = vim.fn.synIDattr(normal, "bg", "gui")
    local background_value = vim.api.nvim_get_color_by_name(background)
    background = background_value >= 0 and string.format("#%06x", background_value)
        or (light and "#ffffff" or "#1f1f1f")
    local colors = vim.deepcopy(palettes[light and "light" or "dark"])
    local modern = vim.g.colors_name == "vscode_modern"
    return vim.tbl_extend("force", colors, {
        foreground = foreground ~= "" and foreground or (light and "#3b3b3b" or "#cccccc"),
        backdrop = modern and M.filled_borders() and colors.backdrop or background,
        inactive = M.filled_borders() and (modern and colors.inactive or lighten(background, light and 0.22 or 0.06))
            or background,
        active = M.filled_borders() and (modern and colors.active or lighten(background, light and 0.5 or 0.12))
            or background,
    })
end

---Return a status bar with neutral sections and the shared blue mode accent.
---@return table
function M.statusline()
    local colors = M.palette()
    return {
        normal = {
            a = { fg = "#ffffff", bg = colors.accent, gui = "bold" },
            b = { fg = colors.foreground, bg = colors.inactive },
            c = { fg = colors.foreground, bg = colors.backdrop },
        },
        inactive = {
            a = { fg = colors.focused, bg = colors.backdrop },
            b = { fg = colors.focused, bg = colors.backdrop },
            c = { fg = colors.focused, bg = colors.backdrop },
        },
    }
end

local job
local generation = 0
local windows_theme_command = {
    "powershell.exe",
    "-NoProfile",
    "-Command",
    [[[int](Get-ItemProperty -Path 'HKCU:\Software\Microsoft\Windows\CurrentVersion\Themes\Personalize' -Name AppsUseLightTheme).AppsUseLightTheme]],
}

local function is_wsl()
    return vim.uv.os_uname().release:lower():match "microsoft" ~= nil
end

local function fallback_is_dark()
    return (vim.env.WEZTERM_THEME or ""):lower():find "dark" ~= nil
end

local function detected_background(result)
    if result.code ~= 0 then
        return nil
    end
    local value = tonumber(result.stdout)
    if value == 0 then
        return true
    elseif value == 1 then
        return false
    end
end

local function apply_theme(dark)
    local scheme = "vscode_modern"
    local background = dark and "dark" or "light"
    vim.opt.termguicolors = true
    if vim.g.colors_name ~= scheme or vim.o.background ~= background then
        -- Avoid loading the old colorscheme again when changing 'background'.
        vim.g.colors_name = nil
        vim.o.background = background
        pcall(vim.cmd.colorscheme, scheme)
    end
end

---Define guide colors before indent-blankline validates or rebuilds its highlights.
function M.reading_highlights()
    local colors = M.palette()
    vim.api.nvim_set_hl(0, "ReadingIndent", { fg = colors.indent, nocombine = true })
    vim.api.nvim_set_hl(0, "ReadingScope", { fg = colors.accent, nocombine = true })
end

local function apply_theme_highlights()
    local cursor = vim.api.nvim_get_hl(0, { name = "Cursor", link = false })
    cursor.blend = 0
    cursor.nocombine = true
    vim.api.nvim_set_hl(0, "NoiceCursor", cursor)
    local colors = M.palette()
    vim.api.nvim_set_hl(0, "DiffAdd", { bg = colors.add })
    vim.api.nvim_set_hl(0, "DiffDelete", { fg = colors.removed, bg = colors.delete })
    vim.api.nvim_set_hl(0, "DiffChange", { bg = colors.change })
    vim.api.nvim_set_hl(0, "DiffText", { bg = colors.text, bold = true })
    vim.api.nvim_set_hl(0, "RenderMarkdownCode", { bg = colors.code })
    vim.api.nvim_set_hl(0, "RenderMarkdownCodeInline", { bg = colors.code })
    local normal = vim.api.nvim_get_hl(0, { name = "Normal", link = false })
    vim.api.nvim_set_hl(0, "WinSeparator", {
        fg = colors.border,
        bg = normal.bg,
    })
    local frame = M.palette()
    vim.api.nvim_set_hl(0, "TabLineSel", { fg = "#ffffff", bg = frame.accent, bold = true })
    vim.api.nvim_set_hl(0, "TabLine", { fg = frame.foreground, bg = frame.inactive })
    vim.api.nvim_set_hl(0, "TabLineFill", { bg = frame.backdrop })
    vim.api.nvim_set_hl(0, "CursorLineNr", { fg = frame.accent, bold = true })
    for _, name in ipairs { "CursorLine", "NvimTreeCursorLine", "NeoTreeCursorLine" } do
        vim.api.nvim_set_hl(0, name, { bg = frame.selection })
    end
    M.reading_highlights()
    vim.api.nvim_set_hl(0, "TreesitterContext", { fg = frame.foreground, bg = frame.inactive })
    vim.api.nvim_set_hl(0, "TreesitterContextLineNumber", { fg = frame.border, bg = frame.inactive })
    vim.api.nvim_set_hl(0, "ScrollView", { fg = frame.border })
    vim.api.nvim_set_hl(0, "ScrollViewHover", { fg = frame.accent })
    vim.api.nvim_set_hl(0, "ScrollViewRestricted", { fg = frame.focused })
    vim.api.nvim_set_hl(0, "FramedNormal", { fg = normal.fg, bg = frame.active })
    vim.api.nvim_set_hl(0, "FramedNormalNC", { fg = normal.fg, bg = frame.inactive })
    vim.api.nvim_set_hl(0, "FramedBackdrop", { fg = frame.backdrop, bg = frame.backdrop })
    vim.api.nvim_set_hl(0, "FramedPopupBackdrop", { fg = frame.foreground, bg = frame.backdrop })
    vim.api.nvim_set_hl(0, "FramedBackdropEndOfBuffer", { fg = frame.backdrop, bg = frame.backdrop })
    vim.api.nvim_set_hl(0, "FramedPaneActive", {
        fg = M.filled_borders() and frame.active or frame.focused,
        bg = frame.backdrop,
    })
    vim.api.nvim_set_hl(0, "FramedPaneBorder", {
        fg = M.filled_borders() and frame.inactive or frame.border,
        bg = frame.backdrop,
    })
    for suffix, background in pairs { [""] = frame.active, NC = frame.inactive } do
        vim.api.nvim_set_hl(0, "FramedPaneTitle" .. suffix, {
            fg = suffix == "" and frame.focused or frame.border,
            bg = M.filled_borders() and background or frame.backdrop,
        })
        vim.api.nvim_set_hl(0, "FramedWinBar" .. suffix, { fg = frame.foreground, bg = background })
        vim.api.nvim_set_hl(0, "FramedEndOfBuffer" .. suffix, { fg = background, bg = background })
        for source, target in pairs {
            SignColumn = "FramedSignColumn",
            FoldColumn = "FramedFoldColumn",
            LineNr = "FramedLineNr",
            CursorLineNr = "FramedCursorLineNr",
        } do
            local highlight = vim.api.nvim_get_hl(0, { name = source, link = false })
            highlight.bg = background
            vim.api.nvim_set_hl(0, target .. suffix, highlight)
        end
    end
    for _, group in ipairs { "NvimTreeWinSeparator", "NeoTreeWinSeparator", "NeoTreeVertSplit", "DiffviewWinSeparator" } do
        vim.api.nvim_set_hl(0, group, { link = "WinSeparator" })
    end
    for _, group in ipairs { "NvimTreeNormal", "NvimTreeNormalNC", "NeoTreeNormal", "NeoTreeNormalNC" } do
        vim.api.nvim_set_hl(0, group, { fg = normal.fg, bg = frame.inactive })
    end
end

---Update the system theme without blocking the editor or overlapping subprocesses.
function M.refresh()
    if not is_wsl() then
        apply_theme(fallback_is_dark())
        return
    end
    if job then
        return
    end
    local current_generation = generation
    job = vim.system(
        windows_theme_command,
        { text = true },
        vim.schedule_wrap(function(result)
            if generation ~= current_generation then
                return
            end
            job = nil
            local dark = detected_background(result)
            if dark ~= nil then
                apply_theme(dark)
            end
        end)
    )
end

---Release any pending system-theme query.
function M.stop()
    generation = generation + 1
    if job then
        job:kill(15)
        job = nil
    end
end

---Install persistent highlights and select the initial theme before drawing the workspace.
function M.setup()
    M.stop()
    vim.opt.winblend = M.popup_blend
    local group = vim.api.nvim_create_augroup("ThemeReadability", { clear = true })
    vim.api.nvim_create_user_command("PaneStyle", function(command)
        if command.args ~= "filled" and command.args ~= "outline" then
            vim.notify("Use :PaneStyle filled or :PaneStyle outline", vim.log.levels.ERROR)
            return
        end
        vim.g.framed_border_style = command.args
        apply_theme_highlights()
        vim.api.nvim_exec_autocmds("User", { pattern = "FramedStyleChanged" })
        require("framed_layout").resize()
    end, {
        nargs = 1,
        complete = function()
            return { "filled", "outline" }
        end,
        desc = "Select filled pane edges or homogeneous outlined frames",
    })
    vim.api.nvim_create_autocmd("ColorScheme", {
        group = group,
        callback = apply_theme_highlights,
    })
    vim.api.nvim_create_autocmd("FocusGained", {
        group = group,
        nested = true,
        callback = M.refresh,
    })
    vim.api.nvim_create_autocmd("VimLeavePre", {
        group = group,
        callback = M.stop,
    })
    local dark = fallback_is_dark()
    if is_wsl() then
        local detected = detected_background(vim.system(windows_theme_command, { text = true }):wait())
        if detected ~= nil then
            dark = detected
        end
    end
    apply_theme(dark)
    apply_theme_highlights()
end

return M
