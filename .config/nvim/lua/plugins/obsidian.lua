return {
  'obsidian-nvim/obsidian.nvim',
  version = '*',
  lazy = false,
  ft = 'markdown',
  event = {
    'BufReadPre ' .. vim.fn.expand '~' .. '/personal/obsidian-vault/*.md',
    'BufNewFile ' .. vim.fn.expand '~' .. '/personal/obsidian-vault/*.md',
  },
  dependencies = {
    'nvim-lua/plenary.nvim',
  },
  -- TODO: flesh out these keymappings
  keys = function()
    local map = function(keys, func, desc)
      vim.keymap.set('n', keys, func, { desc = 'obsidian: ' .. desc })
    end

    map('<leader>of', '<cmd>ObsidianQuickSwitch<CR>', 'search notes')
  end,
  opts = {
    workspaces = {
      {
        name = 'vault',
        path = '~/vaults/obsidian-vault',
      },
    },
    completion = {
      blink = true,
    },
  },
}
