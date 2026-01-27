return {
  { -- TODO: investigate why TodoTrouble errors
    'folke/todo-comments.nvim',
    dependencies = { 'nvim-lua/plenary.nvim' },
    cmd = { 'TodoTelescope' },
    event = 'VimEnter',
    config = true,
    keys = {
      {
        '<leader>st',
        function()
          Snacks.picker.todo_comments()
        end,
        desc = 'Todo',
      },
      {
        '<leader>sT',
        function()
          Snacks.picker.todo_comment { keywords = { 'TODO', 'FIX', 'FIXME' } }
        end,
        desc = 'Todo/Fix/Fixme',
      },
    },
  },
}
