return {
  'neovim/nvim-lspconfig',
  dependencies = {
    { 'saghen/blink.cmp' },
    {
      'williamboman/mason.nvim',
      config = true,
      opts = {
        ui = {
          border = 'rounded',
          height = 0.8,
        },
      },
    },
    'williamboman/mason-lspconfig.nvim',
    'WhoIsSethDaniel/mason-tool-installer.nvim',
    {
      'j-hui/fidget.nvim',
      opts = {
        notification = {
          window = {
            winblend = 0,
          },
        },
      },
    },
    {
      'folke/lazydev.nvim',
      ft = 'lua', -- only load on lua files
      opts = {
        library = {
          -- See the configuration section for more details
          -- Load luvit types when the `vim.uv` word is found
          { path = '${3rd}/luv/library', words = { 'vim%.uv' } },
        },
      },
    },
  },
  config = function()
    vim.api.nvim_create_autocmd('LspAttach', {
      group = vim.api.nvim_create_augroup('tibtab-lsp-attach', { clear = true }),
      callback = function(event)
        local map = function(keys, func, desc)
          vim.keymap.set('n', keys, func, { buffer = event.buf, desc = 'lsp: ' .. desc })
        end

        map('gd', require('telescope.builtin').lsp_definitions, 'goto definition')
        map('gr', require('telescope.builtin').lsp_references, 'goto references')

        map('gI', require('telescope.builtin').lsp_implementations, 'goto implementation')
        map('<leader>ld', require('telescope.builtin').lsp_type_definitions, 'type definition')

        map('<leader>ld', require('telescope.builtin').lsp_document_symbols, 'document symbols')
        map('<leader>lw', require('telescope.builtin').lsp_dynamic_workspace_symbols, 'workspace symbols')

        map('<leader>lr', vim.lsp.buf.rename, 'rename')
        map('<leader>lc', vim.lsp.buf.code_action, 'code action')
        map('K', vim.lsp.buf.hover, 'hover documentation')

        local client = vim.lsp.get_client_by_id(event.data.client_id)
        if client and client.server_capabilities.documentHighlightProvider then
          local highlight_augroup = vim.api.nvim_create_augroup('tibtab-lsp-highlight', { clear = false })
          vim.api.nvim_create_autocmd({ 'CursorHold', 'CursorHoldI' }, {
            buffer = event.buf,
            group = highlight_augroup,
            callback = vim.lsp.buf.document_highlight,
          })

          vim.api.nvim_create_autocmd({ 'CursorMoved', 'CursorMovedI' }, {
            buffer = event.buf,
            group = highlight_augroup,
            callback = vim.lsp.buf.clear_references,
          })

          vim.api.nvim_create_autocmd('LspDetach', {
            group = vim.api.nvim_create_augroup('tibtab-lsp-detach', { clear = true }),
            callback = function(event2)
              vim.lsp.buf.clear_references()
              vim.api.nvim_clear_autocmds { group = 'tibtab-lsp-highlight', buffer = event2.buf }
            end,
          })
        end

        if client and client.server_capabilities.inlayHintProvider and vim.lsp.inlay_hint then
          map('<leader>th', function()
            vim.lsp.inlay_hint.enable(not vim.lsp.inlay_hint.is_enabled())
          end, 'toggle inlay hints')
        end
      end,
    })

    local capabilities = vim.lsp.protocol.make_client_capabilities()
    capabilities = vim.tbl_deep_extend('force', capabilities, require('blink.cmp').get_lsp_capabilities())

    local servers = {
      pyright = {},
      gopls = {},
      clangd = {},
      rust_analyzer = {},
      prettier = {},
      cpptools = {},
      cssls = {},
      denols = {},
      hyprls = {},
      tailwindcss = {},
      glsl_analyzer = {},
      wgsl_analyzer = {},
      markdown_oxide = {},
      emmet_language_server = {
        filetypes = { 'css', 'html', 'javascript', 'javascriptreact', 'astro' },
      },
      lua_ls = {
        settings = {
          Lua = {
            completion = {
              callSnippet = 'Replace',
            },
          },
        },
      },
    }

    require('mason').setup()

    local ensure_installed = vim.tbl_keys(servers or {})
    vim.list_extend(ensure_installed, {
      'stylua',
      'clang-format',
      'isort',
      'black',
    })

    require('mason-tool-installer').setup { ensure_installed = ensure_installed }
    require('mason-lspconfig').setup {
      handlers = {
        function(server_name)
          local server = servers[server_name] or {}
          server.capabilities = vim.tbl_deep_extend('force', {}, capabilities, server.capabilities or {})
          require('lspconfig')[server_name].setup(server)
        end,
      },
    }
  end,
}
