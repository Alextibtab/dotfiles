return {
  'obsidian-nvim/obsidian.nvim',
  version = '*',
  lazy = false,
  ft = 'markdown',
  event = {
    'BufReadPre ' .. vim.fn.expand '~' .. '/personal/obsidian-vault/*.md',
    'BufNewFile ' .. vim.fn.expand '~' .. '/personal/obsidian-vault/*.md',
  },
  -- TODO: flesh out these keymappings
  keys = function()
    local map = function(keys, func, desc)
      vim.keymap.set('n', keys, func, { desc = 'obsidian: ' .. desc })
    end

    map('<leader>of', '<cmd>Obsidian quick_switch<CR>', 'search notes')
  end,
  opts = {
    legacy_commands = false,
    attachments = {
      folder = '.Attachments',
    },
    workspaces = {
      {
        name = 'public',
        path = '~/vaults/obsidian-vault/public-notes',
      },
      {
        name = 'private',
        path = '~/vaults/obsidian-vault/private-notes',
      },
    },
    picker = {
      name = 'snacks.pick',
    },
    completion = {
      blink = true,
    },
  },
}
