local vault_directory

if vim.fn.has 'win32' == 1 then
  vault_directory = 'C:\\Users\\14ale\\vault\\obsidian-vault'
else
  vault_directory = '~/personal/obsidian-vault/'
end

return {
  'epwalsh/obsidian.nvim',
  version = '*',
  lazy = false,
  -- FIX: this breaks nvim on windows
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
        path = vault_directory,
      },
    },
  },
}
