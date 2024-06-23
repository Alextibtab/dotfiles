require('lazy').setup({
  'tpope/vim-sleuth',
  { 'numToStr/Comment.nvim', opts = {} },

  require 'plugins.colorscheme',
  require 'plugins.ui',
  require 'plugins.editor',
  require 'plugins.util',
  require 'plugins.lsp-config',
  require 'plugins.dap-config',
  require 'plugins.treesitter',
  require 'plugins.coding',
  require 'plugins.toggleterm',
  require 'plugins.wakatime',
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
