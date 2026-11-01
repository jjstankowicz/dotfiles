local M = {}

---Return completion, language server, and formatter plugin specifications.
function M.plugins()
    return {
        -- LSP Support
        {
            "neovim/nvim-lspconfig",
            dependencies = {
                "hrsh7th/cmp-nvim-lsp",
            },
        },

        -- Autocompletion
        {
            "hrsh7th/nvim-cmp",
            dependencies = {
                "L3MON4D3/LuaSnip",
                "hrsh7th/cmp-buffer",
                "hrsh7th/cmp-path",
                "hrsh7th/cmp-cmdline",
            },
        },

        -- Formatting and linting
        {
            "nvimtools/none-ls.nvim",
            dependencies = {
                "nvim-lua/plenary.nvim",
            },
        },

        -- Language-server installation
        {
            "williamboman/mason.nvim",
            dependencies = {
                "williamboman/mason-lspconfig.nvim",
            },
            config = function()
                require("mason").setup()
                require("mason-lspconfig").setup {
                    ensure_installed = { "pyright" },
                }
            end,
        },
    }
end

---Configure completion, diagnostics, language servers, and format-on-save.
function M.setup()
    -- Autocompletion setup
    local cmp = require "cmp"
    local luasnip = require "luasnip"

    cmp.setup {
        snippet = {
            expand = function(args)
                luasnip.lsp_expand(args.body)
            end,
        },
        mapping = cmp.mapping.preset.insert {
            ["<C-b>"] = cmp.mapping.scroll_docs(-4),
            ["<C-f>"] = cmp.mapping.scroll_docs(4),
            ["<C-Space>"] = cmp.mapping.complete(),
            ["<C-e>"] = cmp.mapping.abort(),
            ["<CR>"] = cmp.mapping.confirm { select = true },
            ["<C-Tab>"] = cmp.mapping(function(fallback)
                if cmp.visible() then
                    cmp.select_next_item()
                elseif luasnip.expand_or_jumpable() then
                    luasnip.expand_or_jump()
                else
                    fallback()
                end
            end, { "i", "s" }),
            ["<C-S-Tab>"] = cmp.mapping(function(fallback)
                if cmp.visible() then
                    cmp.select_prev_item()
                elseif luasnip.jumpable(-1) then
                    luasnip.jump(-1)
                else
                    fallback()
                end
            end, { "i", "s" }),
        },
        sources = cmp.config.sources({
            { name = "nvim_lsp" },
            { name = "luasnip" },
        }, {
            { name = "buffer" },
            { name = "path" },
        }),
    }

    -- LSP + Linting Setup
    vim.diagnostic.config {
        virtual_text = { -- Keep diagnostics visible inline
            spacing = 4,
            source = "always", -- Show where the diagnostic comes from (LSP/null-ls)
        },
        signs = true, -- Show diagnostic signs in the sign column
        underline = true, -- Underline problematic code
        update_in_insert = false, -- Don't show diagnostics while typing
        severity_sort = true, -- Sort diagnostics by severity
        float = { border = "rounded", source = "always" }, -- Show source in hover
    }

    -- LSP capabilities for completion, applied to all servers
    local capabilities = require("cmp_nvim_lsp").default_capabilities()

    local lspconfig = require "lspconfig"

    -- Pyright setup
    lspconfig.pyright.setup {
        capabilities = capabilities,
        settings = {
            python = {
                analysis = {
                    typeCheckingMode = "basic",
                    diagnosticMode = "workspace",
                    diagnosticSeverityOverrides = {
                        reportGeneralTypeIssues = "error",
                        reportShadowedImports = "error",
                    },
                },
            },
        },
        root_dir = function(fname)
            local util = require "lspconfig.util"
            return util.find_git_ancestor(fname) or util.path.dirname(fname)
        end,
        before_init = function(_, config)
            config.init_options = {
                maxProjectFiles = 10000,
                maxListeners = 20,
            }
        end,
    }

    -- Rust analyzer
    lspconfig.rust_analyzer.setup {
        capabilities = capabilities,
    }

    -- Setup null-ls
    local null_ls = require "null-ls"
    local augroup = vim.api.nvim_create_augroup("LspFormatting", { clear = true })
    null_ls.setup {
        sources = {
            null_ls.builtins.diagnostics.pylint.with {
                condition = function()
                    return vim.fn.executable "pylint" == 1
                end,
            },
            null_ls.builtins.formatting.black.with {
                condition = function()
                    return vim.fn.executable "black" == 1
                end,
                extra_args = { "--line-length", "100" },
            },
            null_ls.builtins.formatting.stylua.with {
                extra_args = { "--config-path", vim.fn.expand "~/.config/nvim/stylua.toml" },
            },
        },
        on_attach = function(client, bufnr)
            -- Enable formatting on save
            if client.supports_method "textDocument/formatting" then
                vim.api.nvim_clear_autocmds { group = augroup, buffer = bufnr }
                vim.api.nvim_create_autocmd("BufWritePre", {
                    group = augroup,
                    buffer = bufnr,
                    callback = function()
                        vim.lsp.buf.format {
                            bufnr = bufnr,
                            filter = function(formatter)
                                return formatter.id == client.id
                            end,
                            timeout_ms = 5000,
                        }
                    end,
                })
            end
        end,
    }

    -- LSP keymaps
    vim.keymap.set("n", "gd", vim.lsp.buf.definition)
    vim.keymap.set("n", "K", vim.lsp.buf.hover)

    -- Hover keymaps
    vim.keymap.set("n", "<leader>e", function()
        vim.diagnostic.open_float(nil, { focusable = true, scope = "cursor" })
    end, { noremap = true, silent = true, desc = "Show diagnostics" })

    vim.keymap.set("n", "gs", vim.lsp.buf.signature_help)
end

return M
