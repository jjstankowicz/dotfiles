-- Exercise prompt editing while background workspace panes remain open.
-- Run with: nvim --headless -n -c "luafile configs/nvim/tests/search-integration.lua"
local prompt
local function text(expected)
    assert(vim.bo.filetype == "TelescopePrompt", "Search lost focus")
    assert(
        vim.api.nvim_get_current_line() == "> " .. expected,
        "Search query changed order: " .. vim.inspect(vim.api.nvim_get_current_line())
    )
    assert(not vim.g.scrollview_enabled, "Scrollbar updates resumed inside the prompt")
end

-- Let scheduled callbacks run after TelescopeFindPre but before Telescope mounts
-- its prompt. This covers UI event loops that expose the pre-window gap.
vim.api.nvim_create_autocmd("User", {
    pattern = "TelescopeFindPre",
    once = true,
    callback = function()
        vim.wait(20, function()
            return false
        end)
    end,
})

local steps = {
    function()
        assert(vim.g.scrollview_enabled)
        require("telescope.builtin").live_grep()
        prompt = vim.api.nvim_get_current_buf()
        local picker = require("telescope.actions.state").get_current_picker(prompt)
        assert(picker.layout_strategy == "flex", "Search lost its responsive layout")
        assert(picker.sorting_strategy == "ascending", "Search prompt moved below its results")
        assert(vim.wo[picker.prompt_win].winblend == require("theme").popup_blend)
        assert(vim.wo[picker.results_win].winblend == require("theme").popup_blend)
    end,
    function()
        text ""
        vim.api.nvim_input "def"
    end,
    function()
        text "def"
        assert(vim.api.nvim_win_get_cursor(0)[2] == 5, "Cursor jumped before the query")
        vim.api.nvim_input "|class"
    end,
    function()
        text "def|class"
        assert(vim.api.nvim_win_get_cursor(0)[2] == 11, "Cursor jumped during search results updates")
        vim.api.nvim_input "<Left><Left><Left>X"
    end,
    function()
        text "def|clXass"
        require("telescope.actions").close(prompt)
    end,
    function()
        assert(vim.g.scrollview_enabled, "Scrollbars did not resume after search")
        require("scrollview").set_state(false)
        require("telescope.builtin").live_grep()
        prompt = vim.api.nvim_get_current_buf()
    end,
    function()
        text ""
        require("telescope.actions").close(prompt)
    end,
    function()
        assert(not vim.g.scrollview_enabled, "Search re-enabled manually disabled scrollbars")
        require("scrollview").set_state(true)
    end,
}
local index = 0
local function advance()
    index = index + 1
    if index > #steps then
        print "PASS: regex prompt typing, cursor placement, middle insertion, scrollbar pause/resume, and disabled state"
        vim.cmd "qa!"
        return
    end
    local ok, err = xpcall(steps[index], debug.traceback)
    if not ok then
        print(err)
        vim.cmd "cquit"
        return
    end
    vim.defer_fn(advance, 200)
end
vim.defer_fn(advance, 1200)
