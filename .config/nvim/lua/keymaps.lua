vim.keymap.set('n', '<C-h>', '<C-w><C-h>', { desc = 'Move focus to the left window' })
vim.keymap.set('n', '<C-l>', '<C-w><C-l>', { desc = 'Move focus to the right window' })
vim.keymap.set('n', '<C-j>', '<C-w><C-j>', { desc = 'Move focus to the lower window' })
vim.keymap.set('n', '<C-k>', '<C-w><C-k>', { desc = 'Move focus to the upper window' })

vim.keymap.set({ 'i', 'x', 'n', 's' }, '<C-s>', '<cmd>w<cr><esc>', { desc = 'Save File' })

function _G.set_terminal_keymaps()
  local opts = { buffer = 0 }
  vim.keymap.set('t', '<Esc>', [[<C-\><C-n>]], opts)
  vim.keymap.set('t', '<C-j>', [[<Cmd>wincmd j<CR>]], opts)
  vim.keymap.set('t', '<C-k>', [[<Cmd>wincmd k<CR>]], opts)
  vim.keymap.set('t', '<C-w>', [[<C-\><C-n><C-w>]], opts)
end

vim.keymap.set('n', '<C-t>', function()
  require('snacks.terminal').toggle()
end, { desc = 'Toggle Snacks terminal', noremap = true, silent = true })

vim.keymap.set('t', '<C-t>', function()
  require('snacks.terminal').toggle()
end, { desc = 'Toggle Snacks terminal', noremap = true, silent = true })

vim.keymap.set('n', '<leader>gg', function()
  require('snacks.lazygit').open()
end, { desc = 'Open git', noremap = true, silent = true })

vim.keymap.set('n', '<leader>gf', function()
  require('snacks.lazygit').log_file()
end, { desc = 'Git file history' })

vim.keymap.set('n', '<leader>gl', function()
  require('snacks.lazygit').log()
end, { desc = 'Git history' })

vim.cmd 'autocmd! TermOpen term://* lua set_terminal_keymaps()'

-- Pick a random theme.
vim.keymap.set('n', '<leader>rt', function()
  local themery = require 'themery'
  local availableThemes = themery.getAvailableThemes()
  if not availableThemes or #availableThemes == 0 then
    print 'No available themes.'
    return
  end

  local randomIndex = math.random(1, #availableThemes)
  themery.setThemeByIndex(randomIndex, false) -- false will set it temporal.
end, { noremap = true })
