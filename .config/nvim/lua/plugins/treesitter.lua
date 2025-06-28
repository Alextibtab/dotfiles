return {
  {
    'nvim-treesitter/nvim-treesitter',
    build = ':TSUpdate',
    opts = {
      ensure_installed = {
        'astro',
        'latex',
        'bash',
        'hyprlang',
        'c',
        'cpp',
        'diff',
        'html',
        'javascript',
        'jsdoc',
        'json',
        'jsonc',
        'lua',
        'luadoc',
        'luap',
        'markdown',
        'markdown_inline',
        'python',
        'query',
        'regex',
        'glsl',
        'toml',
        'tsx',
        'css',
        'typescript',
        'vim',
        'vimdoc',
        'xml',
        'yaml',
      },
      auto_install = true,
      highlight = { enable = true },
      indent = { enable = true },
      incremental_selection = {
        enable = true,
        keymaps = {
          init_selection = '<C-space>',
          node_incremental = '<C-space>',
          scope_incremental = false,
          node_decremental = '<bs>',
        },
      },
    },
    config = function(_, opts)
      require('nvim-treesitter.install').prefer_git = true
      --@diagnostic disable-next-line: missing-fields
      require('nvim-treesitter.configs').setup(opts)
    end,
    dependencies = {
      { 'virchau13/tree-sitter-astro' },
    },
  },
}
