return {
  {
    -- Enable with :TransparentEnable or TransparentToggle
    'xiyaowong/transparent.nvim',
    opts = {
      extra_groups = {
        'NormalFloat',
        'FloatBorder',
        'NeoTreeCursorLine',
        'NeoTreeDimText',
        'NeoTreeDirectoryIcon',
        'NeoTreeDirectoryName',
        'NeoTreeDotfile',
        'NeoTreeFileIcon',
        'NeoTreeFileName',
        'NeoTreeFileNameOpener',
        'NeoTreeFilterTerm',
        'NeoTreeFloatBorder',
        'NeoTreeGitAdded',
        'NeoTreeGitConflict',
        'NeoTreeGitDeleted',
        'NeoTreeGitIgnored',
        'NeoTreeGitModified',
        'NeoTreeGitUnstaged',
        'NeoTreeGitUntracke',
        'NeoTreeGitStaged',
        'NeoTreeHiddenByName',
        'NeoTreeIndentMarker',
        'NeoTreeExpander',
        'NeoTreeNormal',
        'NeoTreeNormalNC',
        'NeoTreeSignColumn',
        'NeoTreeStatusLine',
        'NeoTreeStatusLineNC',
        'NeoTreeVertSplit',
        'NeoTreeWinSeparator',
        'NeoTreeEndOfBuffer',
        'NeoTreeRootName',
        'NeoTreeSymbolicLinkTarget',
        'NeoTreeWindowsHidden',
      },
    },
  },
  {
    -- Default colour theme
    -- TODO: look into telescope colour theme switching
    -- and if I can hook into the function to also change
    -- the status bar simultaneously.
    'catppuccin/nvim',
    lazy = true,
    priority = 1000,
    name = 'catppuccin',
    opts = {
      flavour = 'mocha',
    },
    init = function()
      vim.cmd.colorscheme 'catppuccin'
      vim.api.nvim_set_hl(0, 'LineNr', { fg = '#cdd6f4' })
    end,
  },
}
