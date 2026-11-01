local M = {}
local winbar_highlights = {}

---Render the pinned Bufferline bar in the editor window's winbar context.
---@return string
function M.render()
    local line = _G.nvim_bufferline()
    local normal = vim.wo.winhighlight:match "Normal:(%w+)"
    if not normal or not normal:match "^FramedNormal" then
        return line
    end
    local background = vim.api.nvim_get_hl(0, { name = normal, link = false }).bg
    local suffix = normal == "FramedNormal" and "" or "NC"
    return (
        line:gsub("%%#(BufferLine%w+)#", function(name)
            if name:find "Selected" then
                return "%#" .. name .. "#"
            end
            local target = "Framed" .. name .. suffix
            if winbar_highlights[target] ~= background then
                local highlight = vim.api.nvim_get_hl(0, { name = name, link = false })
                highlight.bg = background
                vim.api.nvim_set_hl(0, target, highlight)
                winbar_highlights[target] = background
            end
            return "%#" .. target .. "#"
        end)
    )
end

local function editor_command(command)
    return function()
        local editor = require("framed_layout").editor()
        if editor and vim.api.nvim_win_get_config(editor).relative ~= "" then
            vim.api.nvim_set_current_win(editor)
        end
        vim.cmd(command)
    end
end

---Return the buffer bar specification and pane-preserving close command.
function M.plugin()
    return {
        "akinsho/bufferline.nvim",
        tag = "v4.9.1",
        lazy = false,
        dependencies = { "nvim-tree/nvim-web-devicons" },
        keys = {
            { "<leader>b<Right>", editor_command "BufferLineCycleNext", desc = "Next file buffer" },
            { "<leader>b<Left>", editor_command "BufferLineCyclePrev", desc = "Previous file buffer" },
            { "<leader>bb", editor_command "BufferLinePick", desc = "Pick file buffer" },
            { "<leader>bd", editor_command "BufferClose", desc = "Close current file buffer" },
        },
        opts = {
            options = {
                mode = "buffers",
                themable = false,
                always_show_bufferline = true,
                auto_toggle_bufferline = false,
                show_close_icon = false,
                show_buffer_close_icons = false,
                separator_style = { "", "" },
                indicator = { style = "icon", icon = "" },
                color_icons = false,
                left_mouse_command = function(buffer)
                    if not require("framed_layout").open_file(vim.api.nvim_buf_get_name(buffer), buffer) then
                        vim.cmd.buffer { args = { tostring(buffer) } }
                    end
                end,
                custom_filter = function(bufnr)
                    return vim.bo[bufnr].buftype == "" and vim.api.nvim_buf_get_name(bufnr) ~= ""
                end,
                offsets = {
                    { filetype = "NvimTree", text = "", padding = 1, highlight = "NvimTreeNormal" },
                    { filetype = "neo-tree", text = "", padding = 1, highlight = "NeoTreeNormal" },
                },
            },
            highlights = function(defaults)
                local highlights = defaults.highlights
                local colors = require("theme").palette()
                for name, highlight in pairs(highlights) do
                    highlight.bg = colors.inactive
                    highlight.italic = false
                    highlight.bold = false
                    highlight.underline = false
                    if name:match "_selected$" then
                        highlight.bg = colors.accent
                        highlight.fg = "#ffffff"
                    end
                end
                highlights.background.fg = { attribute = "fg", highlight = "Comment" }
                highlights.fill.bg = colors.backdrop
                highlights.buffer_selected.bold = true
                return highlights
            end,
        },
        config = function(_, opts)
            require("bufferline").setup(opts)
            local group = vim.api.nvim_create_augroup("FramedBufferHighlights", { clear = true })
            vim.api.nvim_create_autocmd("ColorScheme", {
                group = group,
                callback = function()
                    winbar_highlights = {}
                end,
            })
            vim.api.nvim_create_autocmd("User", {
                group = group,
                pattern = "FramedStyleChanged",
                callback = function()
                    winbar_highlights = {}
                end,
            })
            vim.o.showtabline = 2
            -- Bufferline v4.9.1 refreshes only its global tabline; picker labels also need the winbar.
            local ui = require "bufferline.ui"
            local refresh = ui.refresh
            ui.refresh = function(...)
                refresh(...)
                vim.cmd "redrawstatus"
            end

            vim.api.nvim_create_user_command("BufferClose", function(command)
                if command.args ~= "" then
                    vim.cmd.bdelete { args = command.fargs, bang = command.bang }
                    return
                end

                local current = vim.api.nvim_get_current_buf()
                if vim.bo[current].buftype ~= "" then
                    vim.notify("Select a file buffer to close", vim.log.levels.WARN)
                    return
                end
                if vim.bo[current].modified and not command.bang then
                    vim.notify("No write since last change; save first or use :bd!", vim.log.levels.ERROR)
                    return
                end

                -- Refresh the rendered order before choosing the adjacent file.
                _G.nvim_bufferline()
                local buffers = require("bufferline").get_elements().elements
                local replacement
                for index, buffer in ipairs(buffers) do
                    if buffer.id == current then
                        local neighbor = buffers[index - 1] or buffers[index + 1]
                        replacement = neighbor and neighbor.id
                        break
                    end
                end
                replacement = replacement or vim.api.nvim_create_buf(true, false)
                for _, window in ipairs(vim.fn.win_findbuf(current)) do
                    vim.api.nvim_win_set_buf(window, replacement)
                end
                vim.api.nvim_buf_delete(current, { force = command.bang })
            end, { bang = true, nargs = "*", desc = "Close current file and select the adjacent buffer" })

            vim.cmd [[cnoreabbrev <expr> bd getcmdtype() == ':' && getcmdline() == 'bd' ? 'BufferClose' : 'bd']]
        end,
    }
end

return M
