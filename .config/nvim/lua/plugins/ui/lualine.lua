return {
  { 'AndreM222/copilot-lualine' },
  {
    'nvim-lualine/lualine.nvim',
    dependencies = {
      'nvim-tree/nvim-web-devicons',
    },
    opts = {
      options = {
        theme = 'catppuccin',
        section_separators = { left = '', right = '' },
        component_separators = { left = '', right = '' },
      },
      sections = {
        lualine_a = { { 'mode', icon = '' } },
        lualine_b = { 'branch' },
        lualine_c = {
          {
            'filename',
            path = 1,
            symbols = {
              modified = '●',
              readonly = '',
              unnamed = '󰘓',
              newfile = '',
            },
          },
          {
            'diagnostics',
            symbols = {
              error = ' ',
              warn = ' ',
              info = ' ',
              hint = ' ',
            },
          },
        },
        lualine_x = {
          {
            'diff',
            symbols = {
              added = ' ',
              modified = ' ',
              removed = ' ',
            },
          },
          { 'copilot', show_colors = true },
        },
        lualine_y = { 'filetype' },
        lualine_z = { 'location', 'progress' },
      },
      extensions = {
        'lazy',
        'neo-tree',
        'mason',
      },
    },
  },
}
