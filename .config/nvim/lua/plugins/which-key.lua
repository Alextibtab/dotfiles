return {
  {
    'folke/which-key.nvim',
    event = 'VeryLazy',
    opts = {
      plugins = { spelling = true },
    },
    config = function(_, opts)
      local wk = require 'which-key'
      wk.add {
        { '<leader>a', group = 'avante', icon = '󰭹' },
        { '<leader><tab>', group = 'tabs' },
        { '<leader>c', group = 'code' },
        { '<leader>d', group = 'dap', icon = '' },
        { '<leader>f', group = 'file/find' },
        { '<leader>g', group = 'git' },
        { '<leader>l', group = 'lsp', icon = '' },
        { '<leader>o', group = 'obsidian', icon = '' },
        { '<leader>t', group = 'toggle/trouble' },
        { '<leader>s', group = 'search' },
        { '<leader>n', group = 'noice' },
        { '<leader>u', group = 'ui' },
        { '<leader>w', group = 'windows' },
        { '<leader>x', group = 'diagnostics/quickfix' },
        { '<leader>rt', group = 'random theme' },
        { '[', group = 'prev' },
        { ']', group = 'next' },
        { 'g', group = 'goto' },
        { 'gs', group = 'surround' },
        { 'z', group = 'fold' },
      }
      wk.setup(opts)
    end,
  },
}
