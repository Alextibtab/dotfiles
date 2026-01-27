return {
  'folke/snacks.nvim',
  priority = 1000,
  lazy = false,
  opts = {
    terminal = {
      shell = 'zsh',
      direction = 'float',
      float_opts = {
        width = 0.5,
        height = 0.8,
        border = 'rounded',
      },
    },
    indent = {
      filter = function(buf)
        local excluded_filetypes = {
          'snacks_dashboard',
          'help',
          'alpha',
          'neo-tree',
          'Trouble',
          'trouble',
          'lazy',
          'mason',
          'notify',
          'toggleterm',
          'lazyterm',
          'alpha',
          'NvimTree',
        }
        return vim.g.snacks_indent ~= false
          and vim.b[buf].snacks_indent ~= false
          and vim.bo[buf].buftype == ''
          and not vim.tbl_contains(excluded_filetypes, vim.bo[buf].filetype)
      end,
    },
    dashboard = {
      preset = {
        keys = {
          {
            icon = ' ',
            key = 'f',
            action = function()
              Snacks.picker.files()
            end,
            desc = ' Find File',
          },
          { icon = ' ', key = 'n', action = ':ene | startinsert', desc = ' New File' },
          { icon = ' ', key = 'x', action = ':Leet', desc = ' Leetcode' },
          { icon = ' ', key = 'o', action = ':Obsidian quick_switch', desc = ' Obsidian' },
          {
            icon = ' ',
            key = 'c',
            action = function()
              Snacks.picker.files { cwd = vim.fn.stdpath 'config' }
            end,
            desc = ' Config',
          },
          { icon = ' ', key = 'q', action = ':qa', desc = ' Quit' },
        },
      },

      sections = {
        {
          section = 'terminal',
          cmd = '/home/tibtab/.config/nvim/header.script /home/tibtab/.config/nvim/header.cat',
          indent = -3,
          height = 11,
          width = 72,
        },
        {
          align = 'center',
          text = {
            { '  Update ', hl = 'Label' },
            { ' 󰒲 Lazy ', hl = '@property' },
            { '  Mason', hl = 'Number' },
          },
        },
        { section = 'keys', padding = 1 },
        { icon = ' ', title = 'Recent Files', section = 'recent_files', indent = 2, padding = 1 },
        function()
          local in_git = Snacks.git.get_root() ~= nil
          local cmds = {
            {
              section = 'terminal',
              icon = ' ',
              title = 'Git Status',
              cmd = 'git --no-pager diff --stat -B -M -C',
              enabled = in_git,
              height = 10,
            },
          }
        end,
        { section = 'startup' },
        { text = '', action = ':Lazy update', key = 'u' },
        { text = '', action = ':Lazy', key = 'l' },
        { text = '', action = ':Mason', key = 'm' },
      },
    },
    lazygit = {},
    notifier = {},
    picker = {},
    explorer = {},
    image = {
      resolve = function(path, src)
        local api = require 'obsidian.api'
        if api.path_is_note(path) then
          return api.resolve_attachment_path(src)
        end
      end,
    },
  },
  keys = {
    {
      '<leader><space>',
      function()
        Snacks.picker.smart()
      end,
      desc = 'Smart Find Files',
    },
    {
      '<leader>ff',
      function()
        Snacks.picker.files()
      end,
    },
    {
      '<leader>fh',
      function()
        Snacks.picker.help()
      end,
    },
    {
      '<leader>fc',
      function()
        Snacks.picker.files { cwd = vim.fn.stdpath 'config' }
      end,
      desc = 'Find Config File',
    },
    {
      '<leader>fg',
      function()
        Snacks.picker.git_files()
      end,
      desc = 'Find Git Files',
    },
    {
      '<leader>fe',
      function()
        Snacks.explorer()
      end,
      desc = 'File Explorer',
    },
    {
      '<leader>gb',
      function()
        Snacks.picker.git_branches()
      end,
      desc = 'Git Branches',
    },
    {
      '<leader>gl',
      function()
        Snacks.picker.git_log()
      end,
      desc = 'Git Log',
    },
    {
      '<leader>gL',
      function()
        Snacks.picker.git_log_line()
      end,
      desc = 'Git Log Line',
    },
    {
      '<leader>gs',
      function()
        Snacks.picker.git_status()
      end,
      desc = 'Git Status',
    },
    {
      '<leader>gS',
      function()
        Snacks.picker.git_stash()
      end,
      desc = 'Git Stash',
    },
    {
      '<leader>gd',
      function()
        Snacks.picker.git_diff()
      end,
      desc = 'Git Diff (Hunks)',
    },
    {
      '<leader>gf',
      function()
        Snacks.picker.git_log_file()
      end,
      desc = 'Git Log File',
    },
  },
}
