-- ~/.config/nvim/colors/ayu-hellwal.lua
-- Adaptive colorscheme that works with any hellwal palette

vim.cmd 'hi clear'
if vim.fn.exists 'syntax_on' then
  vim.cmd 'syntax reset'
end

vim.o.background = 'dark'
vim.g.colors_name = 'dynamic'

-- Load colors from hellwal cache
local colors_path = vim.fn.expand '~/.cache/hellwal/colourscheme.lua'
local ok, colors = pcall(dofile, colors_path)

if not ok then
  vim.notify('Hellwal colors not found at ' .. colors_path, vim.log.levels.WARN)
  -- Fallback colors
  colors = {
    bg = '#0f1419',
    fg = '#e6e1cf',
    color0 = '#0f1419',
    color1 = '#ff8f40',
    color2 = '#bae67e',
    color3 = '#ffd580',
    color4 = '#5ccfe6',
    color5 = '#d4bfff',
    color6 = '#95e6cb',
    color7 = '#cbccc6',
    color8 = '#5c6773',
    color9 = '#ff8f40',
    color10 = '#bae67e',
    color11 = '#ffd580',
    color12 = '#5ccfe6',
    color13 = '#d4bfff',
    color14 = '#95e6cb',
    color15 = '#e6e1cf',
  }
end

-- Helper to slightly modify a hex color
local function adjust_color(hex, amount)
  -- Remove # if present
  hex = hex:gsub('#', '')

  -- Convert to RGB
  local r = tonumber(hex:sub(1, 2), 16)
  local g = tonumber(hex:sub(3, 4), 16)
  local b = tonumber(hex:sub(5, 6), 16)

  -- Adjust
  r = math.min(255, math.max(0, r + amount))
  g = math.min(255, math.max(0, g + amount))
  b = math.min(255, math.max(0, b + amount))

  -- Convert back to hex
  return string.format('#%02x%02x%02x', r, g, b)
end

-- Helper function
local function hi(group, opts)
  vim.api.nvim_set_hl(0, group, opts)
end

-- Use the actual bg/fg and create variations
local c = {
  bg = colors.bg or colors.color0,
  fg = colors.fg or colors.color15,

  -- Create subtle variations of the background
  bg_light = adjust_color(colors.bg or colors.color0, 20),
  bg_lighter = adjust_color(colors.bg or colors.color0, 40),
  fg_dim = adjust_color(colors.fg or colors.color15, -60),

  -- Use the palette colors as accents
  -- Distribute them based on contrast with background
  accent1 = colors.color1,
  accent2 = colors.color2,
  accent3 = colors.color3,
  accent4 = colors.color4,
  accent5 = colors.color5,
  accent6 = colors.color6,
  accent7 = colors.color9,
  accent8 = colors.color10,
  accent9 = colors.color11,
  accent10 = colors.color12,
  accent11 = colors.color13,
  accent12 = colors.color14,
}

-- Editor highlights - using subtle bg variations
hi('Normal', { fg = c.fg, bg = c.bg })
hi('NormalFloat', { fg = c.fg, bg = c.bg_light })
hi('FloatBorder', { fg = c.fg_dim })
hi('ColorColumn', { bg = c.bg_light })
hi('Cursor', { fg = c.bg, bg = c.fg })
hi('CursorLine', { bg = c.bg_light }) -- Subtle background shift
hi('CursorLineNr', { fg = c.fg, bold = true })
hi('LineNr', { fg = c.fg_dim })
hi('SignColumn', { bg = c.bg })
hi('VertSplit', { fg = c.bg_lighter, bg = c.bg })
hi('WinSeparator', { fg = c.bg_lighter, bg = c.bg })
hi('Folded', { fg = c.fg_dim, bg = c.bg_light })
hi('FoldColumn', { fg = c.fg_dim })
hi('MatchParen', { bg = c.bg_lighter, bold = true })
hi('NonText', { fg = c.fg_dim })
hi('EndOfBuffer', { fg = c.bg_lighter })

-- Search & Selection
hi('Visual', { bg = c.bg_lighter })
hi('VisualNOS', { bg = c.bg_lighter })
hi('Search', { fg = c.bg, bg = c.accent3 })
hi('IncSearch', { fg = c.bg, bg = c.accent9 })
hi('CurSearch', { fg = c.bg, bg = c.accent9 })

-- Statusline & Tabline
hi('StatusLine', { fg = c.fg, bg = c.bg_light })
hi('StatusLineNC', { fg = c.fg_dim, bg = c.bg })
hi('TabLine', { fg = c.fg_dim, bg = c.bg_light })
hi('TabLineFill', { bg = c.bg })
hi('TabLineSel', { fg = c.fg, bg = c.bg_lighter, bold = true })

-- Popup Menu
hi('Pmenu', { fg = c.fg, bg = c.bg_light })
hi('PmenuSel', { fg = c.bg, bg = c.accent4 })
hi('PmenuSbar', { bg = c.bg_light })
hi('PmenuThumb', { bg = c.bg_lighter })
hi('WildMenu', { fg = c.bg, bg = c.accent4 })

-- Messages - using various accent colors
hi('ErrorMsg', { fg = c.accent1, bold = true })
hi('WarningMsg', { fg = c.accent3, bold = true })
hi('ModeMsg', { fg = c.fg, bold = true })
hi('MoreMsg', { fg = c.accent2 })
hi('Question', { fg = c.accent2 })

-- Syntax Highlighting - distribute accent colors
hi('Comment', { fg = c.fg_dim, italic = true })
hi('Constant', { fg = c.accent3 })
hi('String', { fg = c.accent2 })
hi('Character', { fg = c.accent2 })
hi('Number', { fg = c.accent3 })
hi('Boolean', { fg = c.accent3 })
hi('Float', { fg = c.accent3 })
hi('Identifier', { fg = c.accent12 })
hi('Function', { fg = c.accent4 })
hi('Statement', { fg = c.accent1, bold = true })
hi('Conditional', { fg = c.accent1 })
hi('Repeat', { fg = c.accent1 })
hi('Label', { fg = c.accent1 })
hi('Operator', { fg = c.accent6 })
hi('Keyword', { fg = c.accent1, bold = true })
hi('Exception', { fg = c.accent1 })
hi('PreProc', { fg = c.accent7 })
hi('Include', { fg = c.accent7 })
hi('Define', { fg = c.accent7 })
hi('Macro', { fg = c.accent7 })
hi('PreCondit', { fg = c.accent7 })
hi('Type', { fg = c.accent5 })
hi('StorageClass', { fg = c.accent5 })
hi('Structure', { fg = c.accent5 })
hi('Typedef', { fg = c.accent5 })
hi('Special', { fg = c.accent6 })
hi('SpecialChar', { fg = c.accent6 })
hi('Tag', { fg = c.accent6 })
hi('Delimiter', { fg = c.fg })
hi('SpecialComment', { fg = c.fg_dim, bold = true })
hi('Debug', { fg = c.accent1 })
hi('Underlined', { underline = true })
hi('Ignore', { fg = c.fg_dim })
hi('Error', { fg = c.accent1, bold = true })
hi('Todo', { fg = c.accent3, bold = true })

-- Diff
hi('DiffAdd', { fg = c.accent2 })
hi('DiffChange', { fg = c.accent3 })
hi('DiffDelete', { fg = c.accent1 })
hi('DiffText', { fg = c.bg, bg = c.accent3 })
hi('diffAdded', { fg = c.accent2 })
hi('diffRemoved', { fg = c.accent1 })
hi('diffChanged', { fg = c.accent3 })

-- Spell
hi('SpellBad', { undercurl = true, sp = c.accent1 })
hi('SpellCap', { undercurl = true, sp = c.accent3 })
hi('SpellLocal', { undercurl = true, sp = c.accent4 })
hi('SpellRare', { undercurl = true, sp = c.accent5 })

-- TreeSitter
hi('@comment', { link = 'Comment' })
hi('@string', { link = 'String' })
hi('@number', { link = 'Number' })
hi('@boolean', { link = 'Boolean' })
hi('@function', { link = 'Function' })
hi('@function.call', { link = 'Function' })
hi('@method', { link = 'Function' })
hi('@method.call', { link = 'Function' })
hi('@keyword', { link = 'Keyword' })
hi('@keyword.function', { link = 'Keyword' })
hi('@keyword.return', { link = 'Keyword' })
hi('@conditional', { link = 'Conditional' })
hi('@repeat', { link = 'Repeat' })
hi('@type', { link = 'Type' })
hi('@type.builtin', { link = 'Type' })
hi('@variable', { fg = c.fg })
hi('@variable.builtin', { fg = c.accent12 })
hi('@parameter', { fg = c.accent12 })
hi('@property', { fg = c.accent12 })
hi('@field', { fg = c.accent12 })
hi('@constant', { link = 'Constant' })
hi('@constant.builtin', { link = 'Constant' })
hi('@constructor', { fg = c.accent5 })
hi('@operator', { link = 'Operator' })
hi('@punctuation.delimiter', { fg = c.fg })
hi('@punctuation.bracket', { fg = c.fg })
hi('@punctuation.special', { fg = c.accent6 })
hi('@tag', { fg = c.accent1 })
hi('@tag.attribute', { fg = c.accent4 })
hi('@tag.delimiter', { fg = c.fg })
hi('@text', { fg = c.fg })
hi('@text.emphasis', { italic = true })
hi('@text.strong', { bold = true })
hi('@text.uri', { fg = c.accent6, underline = true })

-- LSP
hi('DiagnosticError', { fg = c.accent1 })
hi('DiagnosticWarn', { fg = c.accent3 })
hi('DiagnosticInfo', { fg = c.accent4 })
hi('DiagnosticHint', { fg = c.accent6 })
hi('DiagnosticUnderlineError', { undercurl = true, sp = c.accent1 })
hi('DiagnosticUnderlineWarn', { undercurl = true, sp = c.accent3 })
hi('DiagnosticUnderlineInfo', { undercurl = true, sp = c.accent4 })
hi('DiagnosticUnderlineHint', { undercurl = true, sp = c.accent6 })
hi('LspReferenceText', { bg = c.bg_light })
hi('LspReferenceRead', { bg = c.bg_light })
hi('LspReferenceWrite', { bg = c.bg_lighter })
hi('LspSignatureActiveParameter', { fg = c.accent4, bold = true })

-- Telescope
hi('TelescopeNormal', { fg = c.fg, bg = c.bg })
hi('TelescopeBorder', { fg = c.bg_lighter })
hi('TelescopePromptPrefix', { fg = c.accent4 })
hi('TelescopeSelection', { bg = c.bg_light })
hi('TelescopeSelectionCaret', { fg = c.accent4 })
hi('TelescopeMatching', { fg = c.accent4, bold = true })

-- NvimTree
hi('NvimTreeNormal', { fg = c.fg, bg = c.bg })
hi('NvimTreeFolderIcon', { fg = c.accent4 })
hi('NvimTreeFolderName', { fg = c.accent4 })
hi('NvimTreeOpenedFolderName', { fg = c.accent4, bold = true })
hi('NvimTreeEmptyFolderName', { fg = c.fg_dim })
hi('NvimTreeRootFolder', { fg = c.accent5, bold = true })
hi('NvimTreeSpecialFile', { fg = c.accent3, underline = true })
hi('NvimTreeGitDirty', { fg = c.accent3 })
hi('NvimTreeGitNew', { fg = c.accent2 })
hi('NvimTreeGitDeleted', { fg = c.accent1 })

-- GitSigns
hi('GitSignsAdd', { fg = c.accent2 })
hi('GitSignsChange', { fg = c.accent3 })
hi('GitSignsDelete', { fg = c.accent1 })

-- Indent Blankline
hi('IndentBlanklineChar', { fg = c.bg_lighter })
hi('IndentBlanklineContextChar', { fg = c.fg_dim })

-- Terminal colors - use the raw palette
vim.g.terminal_color_0 = colors.color0
vim.g.terminal_color_1 = colors.color1
vim.g.terminal_color_2 = colors.color2
vim.g.terminal_color_3 = colors.color3
vim.g.terminal_color_4 = colors.color4
vim.g.terminal_color_5 = colors.color5
vim.g.terminal_color_6 = colors.color6
vim.g.terminal_color_7 = colors.color7
vim.g.terminal_color_8 = colors.color8
vim.g.terminal_color_9 = colors.color9
vim.g.terminal_color_10 = colors.color10
vim.g.terminal_color_11 = colors.color11
vim.g.terminal_color_12 = colors.color12
vim.g.terminal_color_13 = colors.color13
vim.g.terminal_color_14 = colors.color14
vim.g.terminal_color_15 = colors.color15
