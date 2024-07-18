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
        { '<leader><tab>', group = 'tabs' },
        { '<leader>b', group = 'buffer' },
        { '<leader>c', group = 'code' },
        { '<leader>f', group = 'file/find' },
        { '<leader>g', group = 'git' },
        { '<leader>t', group = 'toggle' },
        { '<leader>gh', group = 'hunks' },
        { '<leader>q', group = 'quit/session' },
        { '<leader>s', group = 'search' },
        { '<leader>sn', group = 'noice' },
        { '<leader>u', group = 'ui' },
        { '<leader>w', group = 'windows' },
        { '<leader>x', group = 'diagnostics/quickfix' },
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
