return {
  {
    'nvim-telescope/telescope.nvim',
    tag = '0.1.8',
    lazy = false,
    dependencies = { 'nvim-lua/plenary.nvim', { 'nvim-telescope/telescope-fzf-native.nvim', build = 'make' } },
    config = function()
      require('telescope').setup {
        extensions = {
          fzf = {},
        },
      }
      require('telescope').load_extension 'fzf'
    end,
    keys = {
      { '<leader>fc', '<cmd>Telescope find_files cwd=~/.config/nvim<cr>', desc = 'telescope: find config files' },
      { '<leader>ff', '<cmd>Telescope find_files<cr>', desc = 'telescope: find files' },
      { '<leader>fg', '<cmd>Telescope git_files<cr>', desc = 'telescope: find git files' },
      { '<leader>fr', '<cmd>Telescope oldfiles<cr>', desc = 'telescope: recent files' },
      { '<leader>fh', '<cmd>Telescope help_tags<cr>', desc = 'telescope: find help' },
    },
  },
}
