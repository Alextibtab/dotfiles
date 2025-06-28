return {
  {
    'zaldih/themery.nvim',
    lazy = false,
    config = function()
      require('themery').setup {
        themes = {
          'catppuccin',
          'tokyonight',
          'ayu',
          'kanagawa',
          'kanso',
        },
        default_theme = 'catppuccin',
        livePreview = true,
      }
    end,
  },
}
