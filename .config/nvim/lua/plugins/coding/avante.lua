local build_command

if vim.fn.has 'win32' == 1 then
  build_command = 'powershell -ExecutionPolicy Bypass -File build.ps1 -BuildFromSource false'
else
  build_command = 'make'
end

return {
  'yetone/avante.nvim',
  event = 'VeryLazy',
  lazy = false,
  version = false,
  opts = {
    provider = 'claude',
    claude = {
      api_key_name = 'cmd:bw get notes claude-api-key',
    },
  },
  build = build_command,
  depends = {
    'stevearc/dressing.nvim',
    'nvim-lua/plenary.nvim',
    'MunifTanjim/nui.nvim',
    'nvim-tree/nvim-web-devicons',
    {
      'MeanderingProgrammer/render-markdown.nvim',
      opts = {
        file_types = { 'markdown', 'Avante' },
      },
      ft = { 'markdown', 'Avante' },
    },
  },
}
