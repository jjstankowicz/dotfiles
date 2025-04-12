require('lspconfig').pyright.setup{}

local cmp = require'cmp'

cmp.setup({
  snippet = {
    expand = function(args)
      require('luasnip').lsp_expand(args.body) -- Snippet engine
    end,
  },
  mapping = cmp.mapping.preset.insert({
    ['<C-b>'] = cmp.mapping.scroll_docs(-4),
    ['<C-f>'] = cmp.mapping.scroll_docs(4),
    ['<C-Space>'] = cmp.mapping.complete(),
    ['<C-e>'] = cmp.mapping.abort(),
    ['<CR>'] = cmp.mapping.confirm({ select = true }), -- Accept currently selected item
  }),
  sources = cmp.config.sources({
    { name = 'nvim_lsp' },
    { name = 'buffer' },
    { name = 'path' },
  }),
})

require'nvim-treesitter.configs'.setup {
  ensure_installed = {"python"}, -- Specify parsers to install
  highlight = {
    enable = true,               -- Enable syntax highlighting
    additional_vim_regex_highlighting = false,
  },
}

-- Lua Configuration for nvim-dap
local dap = require('dap')
local dapui = require('dapui')

-- Setup nvim-dap-ui
dapui.setup()

-- Automatically open/close UI during debugging
dap.listeners.after.event_initialized["dapui_config"] = function()
  dapui.open()
end
dap.listeners.before.event_terminated["dapui_config"] = function()
  dapui.close()
end
dap.listeners.before.event_exited["dapui_config"] = function()
  dapui.close()
end

-- Python Debugger configuration
dap.adapters.python = {
  type = 'executable',
  command = 'python', -- Or 'python3' depending on your setup
  args = { '-m', 'debugpy.adapter' },
}

dap.configurations.python = {
  {
    type = 'python',
    request = 'launch',
    name = 'Launch File',
    program = '${file}', -- Debug the current file
    pythonPath = function()
      -- Use the virtualenv or system python
      local venv_path = os.getenv("VIRTUAL_ENV")
      if venv_path then
        return venv_path .. '/bin/python'
      else
        return 'python'
      end
    end,
  },
}


local null_ls = require("null-ls")

null_ls.setup({
    sources = {
        null_ls.builtins.formatting.black, -- Python formatter
        null_ls.builtins.diagnostics.flake8, -- Python linter
    },
})

require'lspconfig'.terraformls.setup{}
