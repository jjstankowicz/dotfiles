-- Restore the shared plugin specifications without starting the interactive UI.
local function restore()
    local config_dir = assert(arg[1], "Missing configuration directory")
    vim.go.loadplugins = true
    vim.opt.rtp:prepend(config_dir)
    local lock_lines = vim.fn.readfile(config_dir .. "/lazy-lock.json")
    local lock = vim.json.decode(table.concat(lock_lines, "\n"))
    local lazy_dir = vim.fn.stdpath "data" .. "/lazy/lazy.nvim"
    local function run(command)
        local result = vim.system(command, { text = true }):wait()
        assert(result.code == 0, result.stderr or "Command failed")
    end
    if vim.fn.isdirectory(lazy_dir) == 0 then
        run { "git", "clone", "--filter=blob:none", "https://github.com/folke/lazy.nvim.git", lazy_dir }
    end
    assert(lock["lazy.nvim"], "Missing lazy.nvim pin")
    run { "git", "-C", lazy_dir, "fetch", "origin", lock["lazy.nvim"].commit }
    run { "git", "-C", lazy_dir, "checkout", "--detach", lock["lazy.nvim"].commit }
    vim.opt.rtp:prepend(lazy_dir)
    -- Keep sources, pins, dependencies, and build hooks; defer interactive setup.
    local function install_spec(spec)
        if type(spec) ~= "table" then
            return spec
        end
        local result = vim.deepcopy(spec)
        if type(spec[1]) == "string" then
            for _, key in ipairs { "init", "opts", "event", "cmd", "keys", "ft" } do
                result[key] = nil
            end
            result.config = false
            result.lazy = true
            if result.dependencies then
                for index, dependency in ipairs(result.dependencies) do
                    result.dependencies[index] = install_spec(dependency)
                end
            end
        else
            for index, child in ipairs(spec) do
                result[index] = install_spec(child)
            end
        end
        return result
    end
    require("lazy").setup {
        spec = install_spec(require "plugins"),
        lockfile = config_dir .. "/lazy-lock.json",
        defaults = { lazy = true },
        install = { missing = false },
        checker = { enabled = false },
        change_detection = { enabled = false },
    }
    local function check_tasks()
        for name, plugin in pairs(require("lazy.core.config").plugins) do
            for _, task in ipairs(plugin._.tasks or {}) do
                assert(not task:has_errors(), "Plugin operation failed: " .. name .. "\n" .. task:output())
            end
        end
    end
    require("lazy").install { wait = true, show = false, lockfile = true }
    check_tasks()
    vim.fn.writefile(lock_lines, config_dir .. "/lazy-lock.json")
    require("lazy.manage.lock").lock = vim.deepcopy(lock)
    local changed_plugins = {}
    for name, pin in pairs(lock) do
        local plugin = require("lazy.core.config").plugins[name]
        if plugin then
            local result = vim.system({ "git", "-C", plugin.dir, "rev-parse", "HEAD" }, { text = true }):wait()
            if result.code ~= 0 or vim.trim(result.stdout) ~= pin.commit then
                table.insert(changed_plugins, name)
            end
        end
    end
    -- Matching plugins can contain the generated Markdown navigation bridge.
    -- Leave them intact; Lazy refuses to update modified tracked plugin files.
    if #changed_plugins > 0 then
        require("lazy").restore { wait = true, show = false, plugins = changed_plugins }
    end
    check_tasks()
    for name, pin in pairs(lock) do
        local plugin = require("lazy.core.config").plugins[name]
        if plugin then
            local result = vim.system({ "git", "-C", plugin.dir, "rev-parse", "HEAD" }, { text = true }):wait()
            assert(result.code == 0 and vim.trim(result.stdout) == pin.commit, "Plugin pin mismatch: " .. name)
        end
    end

    local preview = require("lazy.core.config").plugins["markdown-preview.nvim"]
    local preview_binary = preview.dir .. "/app/bin/markdown-preview-linux"
    if vim.fn.executable(preview_binary) ~= 1 then
        require("lazy").build { plugins = { "markdown-preview.nvim" }, wait = true, show = false }
        check_tasks()
        assert(vim.fn.executable(preview_binary) == 1, "Markdown preview binary is missing or unsupported on this platform")
    end

    require("lazy").load { plugins = { "nvim-treesitter", "mason.nvim" } }
    require("nvim-treesitter.configs").setup { ensure_installed = {} }
    require("mason").setup()
    local parsers = require "nvim-treesitter.parsers"
    -- Use the same parser list as interactive startup.
    local parser_names
    for _, spec in ipairs(require("reading").plugins()) do
        if spec[1] == "nvim-treesitter/nvim-treesitter" then
            parser_names = spec.opts.ensure_installed
        end
    end
    assert(parser_names, "Missing parser list")
    vim.v.errmsg = ""
    vim.cmd("TSUpdateSync " .. table.concat(parser_names, " "))
    assert(vim.v.errmsg == "", "Parser installation failed: " .. vim.v.errmsg)
    for _, name in ipairs(parser_names) do
        assert(parsers.has_parser(name), "Parser installation failed: " .. name)
    end

    local registry = require "mason-registry"
    local refreshed = false
    registry.refresh(function() refreshed = true end)
    assert(vim.wait(300000, function() return refreshed end, 100), "Mason registry refresh timed out")
    local pyright = registry.get_package "pyright"
    if not pyright:is_installed() then
        local finished, success = false, false
        pyright:install():once("closed", function()
            success = pyright:is_installed()
            finished = true
        end)
        assert(vim.wait(300000, function() return finished end, 100), "Pyright installation timed out")
        assert(success, "Pyright installation failed")
    end
end

local ok, message = xpcall(restore, debug.traceback)
if not ok then
    io.stderr:write(message .. "\n")
    vim.cmd "cquit 1"
end
vim.cmd "qa!"
