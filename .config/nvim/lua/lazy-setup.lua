require('lazy').setup({
  'tpope/vim-sleuth',
  { 'numToStr/Comment.nvim', opts = {} },

  -- colourscheme
  require 'plugins.other.colorscheme',

  -- lsp configuration
  require 'plugins.lsp.nvim-lspconfig',

  -- debugging configuration
  require 'plugins.dap.nvim-dap',

  -- ui plugins
  require 'plugins.ui.noice',
  require 'plugins.ui.nvim-notify',
  require 'plugins.ui.nui',
  require 'plugins.ui.dressing',
  require 'plugins.ui.telescope',
  require 'plugins.ui.nvim-web-devicons',
  require 'plugins.ui.neo-tree',
  require 'plugins.ui.lualine',
  require 'plugins.ui.toggleterm',
  require 'plugins.ui.which-key',
  require 'plugins.ui.dashboard',

  -- coding plugins
  require 'plugins.coding.nvim-cmp',
  require 'plugins.coding.treesitter',
  require 'plugins.coding.mini',
  require 'plugins.coding.indent-blankline',
  require 'plugins.coding.nvim-ts-context-commentstring',
  require 'plugins.coding.todo-comments',
  require 'plugins.coding.conform',
  require 'plugins.coding.avante',

  -- utility plugins
  require 'plugins.util.vim-tmux-navigator',

  -- other plugins
  require 'plugins.other.wakatime',
  require 'plugins.other.obsidian',
  require 'plugins.other.leetcode',
  require 'plugins.other.gitsigns',
  require 'plugins.other.screenkey',
}, {
  ui = {
    border = 'rounded',
    icons = vim.g.have_nerd_font and {} or {
      cmd = '⌘',
      config = '🛠',
      event = '📅',
      ft = '📂',
      init = '⚙',
      keys = '🗝',
      plugin = '🔌',
      runtime = '💻',
      require = '🌙',
      source = '📄',
      start = '🚀',
      task = '📌',
      lazy = '💤 ',
    },
  },
})
