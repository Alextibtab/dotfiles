return {
  { -- auto pairs
    'echasnovski/mini.pairs',
    event = 'VeryLazy',
    opts = {
      mappings = {
        ['`'] = { action = 'closeopen', pair = '``', neigh_pattern = '[^\\`].', register = { cr = false } },
      },
    },
    keys = {
      {
        '<leader>tp',
        function()
          vim.g.minipairs_disable = not vim.g.minipairs_disable
          if vim.g.minipairs_disable then
            vim.notify('Disabled auto pairs', 'WARN')
          else
            vim.notify('Enabled auto pairs', 'INFO')
          end
        end,
        desc = 'mini.pairs: toggle auto pairs',
      },
    },
  },
  {
    'echasnovski/mini.comment',
    event = 'VeryLazy',
    opts = {
      options = {
        custom_commentstring = function()
          return require('ts_context_commentstring.internal').calculate_commentstring() or vim.bo.commentstring
        end,
      },
    },
  },
}
