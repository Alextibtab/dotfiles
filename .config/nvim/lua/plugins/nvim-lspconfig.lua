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
    'j-hui/fidget.nvim',
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

        map('gd', function()
          Snacks.picker.lsp_definitions()
        end, 'goto definition')
        map('gr', function()
          Snacks.picker.lsp_references()
        end, 'references')

        map('gI', function()
          Snacks.picker.lsp_implementations()
        end, 'goto implementation')
        map('<leader>ld', function()
          Snacks.picker.lsp_type_definitions()
        end, 'type definition')

        map('<leader>ls', function()
          Snacks.picker.lsp_symbols()
        end, 'document symbols')
        map('<leader>lw', function()
          Snacks.picker.lsp_workspace_symbols()
        end, 'workspace symbols')

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

    -- Servers managed by Mason (excluding clangd)
    local mason_servers = {
      pyright = {},
      gopls = {},
      rust_analyzer = {},
      prettier = {},
      cpptools = {},
      qmlls = {},
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

    local ensure_installed = vim.tbl_keys(mason_servers or {})
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
          -- Skip clangd here since we'll set it up manually
          if server_name == 'clangd' then
            return
          end

          local server = mason_servers[server_name] or {}
          server.capabilities = vim.tbl_deep_extend('force', {}, capabilities, server.capabilities or {})
          vim.lsp.config(server_name, {
            server,
          })
          vim.lsp.enable { server_name }
        end,
      },
    }

    -- Manually setup clangd with system binary and custom flags
    vim.lsp.config('clangd', {
      cmd = { '/usr/bin/clangd', '--experimental-modules-support' },
      capabilities = capabilities,
      -- Additional clangd-specific settings
      init_options = {
        usePlaceholders = true,
        completeUnimported = true,
      },
      -- Ensure it uses the same compile commands as your build
      root_maerkers = {
        '.clangd',
        '.clang-tidy',
        '.clang-format',
        'compile_commands.json',
        'compile_flags.txt',
        '.git',
      },
    })
    vim.lsp.enable { 'clangd' }
  end,
}
