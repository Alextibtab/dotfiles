return {
  {
    -- Default colour theme
    -- TODO: look into telescope colour theme switching
    -- and if I can hook into the function to also change
    -- the status bar simultaneously.
    'catppuccin/nvim',
    lazy = true,
    priority = 1000,
    name = 'catppuccin',
    opts = {
      flavour = 'mocha',
    },
    init = function()
      vim.cmd.colorscheme 'catppuccin'
      vim.api.nvim_set_hl(0, 'LineNr', { fg = '#cdd6f4' })
    end,
  },
  {
    'Shatur/neovim-ayu',
    lazy = false,
    config = function()
      require('ayu').setup {
        mirage = true,
        terminal = true,
      }
    end,
  },
  {
    'webhooked/kanso.nvim',
    lazy = false,
  },
  {
    'rebelot/kanagawa.nvim',
    lazy = false,
  },
  {
    'folke/tokyonight.nvim',
    lazy = false,
  },
}
