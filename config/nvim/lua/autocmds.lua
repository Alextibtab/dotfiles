local function augroup(name)
  return vim.api.nvim_create_augroup('tibtab_' .. name, { clear = true })
end

vim.api.nvim_create_autocmd('TextYankPost', {
  group = augroup 'highlight_yank',
  callback = function()
    vim.highlight.on_yank()
  end,
})

vim.api.nvim_create_autocmd({ 'BufEnter', 'BufWinEnter' }, {
  pattern = { '*.hl', 'hypr*.conf' },
  callback = function()
    vim.lsp.start {
      name = 'hyprland',
      cmd = { 'hyprls' },
      root_dir = vim.fn.getcwd(),
    }
  end,
})

vim.api.nvim_create_autocmd('FileType', {
  group = augroup 'close_with_q',
  pattern = {
    'PlenaryTestPopup',
    'help',
    'lspinfo',
    'notify',
    'qf',
    'query',
    'spectre_panel',
    'startuptime',
    'tsplayground',
    'neotest-output',
    'checkhealth',
    'neotest-summary',
    'neotest-output-panel',
  },
  callback = function(event)
    vim.bo[event.buf].buflisted = false
    vim.keymap.set('n', 'q', '<cmd>close<cr>', { buffer = event.buf, silent = true })
  end,
})
