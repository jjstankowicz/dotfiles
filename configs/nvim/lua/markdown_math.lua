local M = {}

---Replace standalone display math while retaining the plugin's conversion and editing behavior.
---@param context render.md.handler.Context
---@return render.md.Mark[]
function M.parse(context)
    local marks = require("render-markdown.handler.latex").parse(context)
    if not context.last then
        return marks
    end
    local request = require("render-markdown.request.context").get(context.buf)
    for _, node in ipairs(request.latex:get()) do
        if node:height() > 1 then
            local first = vim.api.nvim_buf_get_lines(context.buf, node.start_row, node.start_row + 1, false)[1]
            local last = vim.api.nvim_buf_get_lines(context.buf, node.end_row, node.end_row + 1, false)[1]
            if first and last and first:match "^%s*%$%$%s*$" and last:match "^%s*%$%$%s*$" then
                for _, mark in ipairs(marks) do
                    if mark.start_row == node.start_row and mark.opts.virt_lines then
                        mark.replace = mark.opts.virt_lines
                        mark.conceal = "latex"
                        mark.opts = {
                            end_row = node.end_row,
                            end_col = node.end_col,
                            conceal_lines = "",
                        }
                    end
                end
            end
        end
    end
    return marks
end

return M
