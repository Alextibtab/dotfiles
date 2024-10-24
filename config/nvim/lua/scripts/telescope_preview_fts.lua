local previewers = require 'telescope.previewers'
local putils = require 'telescope.previewers.utils'
local pfiletype = require 'plenary.filetype'

local hypr_maker = function(filepath, bufnr, opts)
  opts = opts or {}
  if opts.use_ft_detect == nil then
    local ft = pfiletype.detect(filepath, opts)
    if ft == 'hyprlang' then
      return 'hyprlang'
    else
      return nil
    end
    opts.use_ft_detect = false
    putils.regex_highlighter(bufnr, ft)
  end
  previewers.buffer_previewer_maker(filepath, bufnr, opts)
end

require('telescope').setup {
  defaults = {
    buffer_previewer_maker = hypr_maker,
  },
}
