require('lazy').setup({
  'tpope/vim-sleuth', 
  { 'numToStr/Comment.nvim', opts = {} },

  require 'plugins.colorscheme',
  require 'plugins.lsp-config',
  require 'plugins.treesitter',
  require 'plugins.coding',
  require 'plugins.ui',
  require 'plugins.editor',
  require 'plugins.util',
}, {
  ui = {
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

