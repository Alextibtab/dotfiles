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
        header = [[
 .o88o.                               o8o                .              
 888 `"                               `"'              .o8              
o888oo   .oooo.o  .ooooo.   .ooooo.  oooo   .ooooo.  .o888oo oooo    ooo
 888    d88(  "8 d88' `88b d88' `"Y8 `888  d88' `88b   888    `88.  .8' 
 888    `"Y88b.  888   888 888        888  888ooo888   888     `88..8'  
 888    o.  )88b 888   888 888   .o8  888  888    .o   888 .    `888'   
o888o   8""888P' `Y8bod8P' `Y8bod8P' o888o `Y8bod8P'   "888"      d8'   
                                                             .o...P'    
                                                             `XER0'     ]],
        keys = {
          { icon = ' ', key = 'f', action = ':Telescope find_files', desc = ' Find File' },
          { icon = ' ', key = 'n', action = ':ene | startinsert', desc = ' New File' },
          { icon = ' ', key = 'x', action = ':Leet', desc = ' Leetcode' },
          { icon = ' ', key = 'o', action = ':ObsidianQuickSwitch', desc = ' Obsidian' },
          { icon = ' ', key = 'r', action = ':Telescope oldfiles', desc = ' Recent Files' },
          { icon = ' ', key = 'g', action = ':Telescope live_grep', desc = ' Find Text' },
          { icon = ' ', key = 'c', action = ':Telescope find_files cwd=~/.config/nvim', desc = ' Config' },
          { icon = ' ', key = 'm', action = ':Mason', desc = ' Mason' },
          { icon = '󰒲 ', key = 'l', action = ':Lazy', desc = ' Lazy' },
          { icon = ' ', key = 'q', action = ':qa', desc = ' Quit' },
        },
      },

      sections = {
        { section = 'header' },
        { section = 'terminal', pane = 2, cmd = '', height = 8, padding = 1 },
        { section = 'keys', gap = 1, padding = 1 },
        {
          pane = '2',
          icon = ' ',
          desc = 'Browse Repo',
          padding = 1,
          key = 'b',
          action = function()
            require('snacks').gitbrowse()
          end,
        },
        { pane = 2, icon = ' ', title = 'Recent Files', section = 'recent_files', indent = 2, padding = 1 },
        { pane = 2, icon = ' ', title = 'Projects', section = 'projects', indent = 2, padding = 1 },
        {
          pane = 2,
          icon = ' ',
          title = 'Git Status',
          section = 'terminal',
          enabled = function()
            return Snacks.git.get_root() ~= nil
          end,
          cmd = 'git status --short --branch --renames',
          height = 5,
          padding = 1,
          ttl = 5 * 60,
          indent = 3,
        },
        { section = 'startup' },
      },
    },
    lazygit = {},
  },
}
