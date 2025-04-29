return {
  { -- auto format
    'stevearc/conform.nvim',
    lazy = false,
    opts = {
      notify_on_error = false,
      format_on_save = function(bufnr)
        return {
          timeout_ms = 1000,
          lsp_fallback = vim.bo[bufnr].filetype,
        }
      end,
      formatters_by_ft = {
        lua = { 'stylua' },
        python = { 'isort', 'black' },
        cpp = { 'clang-format' },
        cs = { 'csharpier' },
        rust = { 'rustfmt' },
      },
    },
  },
}
