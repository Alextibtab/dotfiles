return {
  {
    'nvim-telescope/telescope.nvim',
    lazy = false,
    priority = 100,
    dependencies = {
      'nvim-lua/plenary.nvim',
      { 'nvim-telescope/telescope-fzf-native.nvim', build = 'cmake -S. -Bbuild -DCMAKE_BUILD_TYPE=Release && cmake --build build --config Release' },
    },
    config = function()
      require('telescope').setup {
        extensions = {
          fzf = {
            fuzzy = true,
            override_generic_sorter = true,
            override_file_sorter = true,
            case_mode = 'smart_case',
          },
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
