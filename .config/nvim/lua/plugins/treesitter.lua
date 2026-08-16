return {
  {
    'nvim-treesitter/nvim-treesitter',
    branch = 'main',
    build = ':TSUpdate',
    config = function()
      local parsers = {
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
      }
      require('nvim-treesitter').install(parsers)

      ---@param buf integer
      ---@param language string
      local function try_attach(buf, language)
        if not vim.treesitter.language.add(language) then return end
        vim.treesitter.start(buf, language)
        local has_indent = vim.treesitter.query.get(language, 'indents') ~= nil
        if has_indent then
          vim.bo[buf].indentexpr = "v:lua.require'nvim-treesitter'.indentexpr()"
        end
      end

      local available = require('nvim-treesitter').get_available()
      vim.api.nvim_create_autocmd('FileType', {
        callback = function(args)
          local buf = args.buf
          local language = vim.treesitter.language.get_lang(args.match)
          if not language then return end
          local installed = require('nvim-treesitter').get_installed 'parsers'
          if vim.tbl_contains(installed, language) then
            try_attach(buf, language)
          elseif vim.tbl_contains(available, language) then
            require('nvim-treesitter').install(language):await(function()
              try_attach(buf, language)
            end)
          else
            try_attach(buf, language)
          end
        end,
      })
    end,
  },
}