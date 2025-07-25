return {
  {
    'nvim-lualine/lualine.nvim',
    dependencies = {
      'nvim-tree/nvim-web-devicons',
    },
    opts = {
      window = { winblend = 80 },
      options = {
        theme = 'kanso',
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
            separator = '',
            symbols = {
              added = ' ',
              modified = ' ',
              removed = ' ',
            },
          },
          {
            'copilot',
            separator = '',
            symbols = {
              status = {
                icons = {
                  enabled = ' ',
                  sleep = ' ', -- auto-trigger disabled
                  disabled = ' ',
                  warning = ' ',
                  unknown = ' ',
                },
                hl = {
                  enabled = '#50FA7B',
                  sleep = '#AEB7D0',
                  disabled = '#6272A4',
                  warning = '#FFB86C',
                  unknown = '#FF5555',
                },
              },
              spinners = 'dots', -- has some premade spinners
              spinner_color = '#6272A4',
            },
            show_colors = true,
            show_loading = true,
          },
        },
        lualine_y = { 'filetype' },
        lualine_z = { 'location', 'progress' },
      },
      extensions = {
        'lazy',
        'neo-tree',
        'mason',
        'avante',
      },
    },
  },
}
