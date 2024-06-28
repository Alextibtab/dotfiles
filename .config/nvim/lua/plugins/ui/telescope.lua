return {
  {
    'nvim-telescope/telescope.nvim',
    tag = '0.1.6',
    lazy = false,
    dependencies = { 'nvim-lua/plenary.nvim' },
    keys = {
      -- find
      { '<leader>fb', '<cmd>Telescope buffers sort_mru=true sort_lastused=true<cr>', desc = 'Buffers' },
      { '<leader>fc', '<cmd>Telescope find_files cwd=~/.config/nvim<cr>', desc = 'Find Config File' },
      { '<leader>ff', '<cmd>Telescope find_files<cr>', desc = 'Find Files (Root Dir)' },
      { '<leader>fg', '<cmd>Telescope git_files<cr>', desc = 'Find Files (git-files)' },
      { '<leader>fr', '<cmd>Telescope oldfiles<cr>', desc = 'Recent' },
      { '<leader>sh', '<cmd>Telescope help_tags<cr>', desc = 'Search Help' },
    },
  },
}
