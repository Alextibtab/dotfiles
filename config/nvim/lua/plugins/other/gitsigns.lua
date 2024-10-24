return {
  {
    'lewis6991/gitsigns.nvim',
    opts = {
      on_attach = function(bufnr)
        local gitsigns = require 'gitsigns'

        local function map(mode, l, r, opts)
          opts = opts or {}
          opts.buffer = bufnr
          vim.keymap.set(mode, l, r, opts)
        end

        -- toggles
        map('n', '<leader>tb', gitsigns.toggle_current_line_blame, { desc = 'gitsigns: toggle git blame' })
        map('n', '<leader>tD', gitsigns.toggle_deleted, { desc = 'gitsigns: toggle git deleted' })
      end,
    },
  },
}
