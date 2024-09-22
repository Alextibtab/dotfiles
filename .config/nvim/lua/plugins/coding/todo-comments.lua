return {
  { -- TODO: investigate why TodoTrouble errors
    'folke/todo-comments.nvim',
    dependencies = { 'nvim-lua/plenary.nvim' },
    cmd = { 'TodoTelescope' },
    event = 'VimEnter',
    config = true,
    keys = {
      { '<leader>st', '<cmd>TodoTelescope<cr>', desc = 'telescope: todo' },
      { '<leader>sT', '<cmd>TodoTelescope keywords=TODO,FIX,FIXME<cr>', desc = 'telescope: todo/fix/fixme' },
    },
  },
}
