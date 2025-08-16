local M = {}
local uv = vim.loop
local handle = nil

local function reload()
  vim.schedule(function()
    local cache = vim.fn.expand '~/.cache/hellwal/colourscheme.lua'
    local colors = vim.fn.expand '~/.config/nvim/colors/dynamic.lua'

    if vim.fn.filereadable(cache) == 1 then
      vim.cmd('hi clear | source ' .. colors .. ' | colorscheme dynamic')
    end
  end)
end

function M.setup()
  if handle then
    uv.fs_event_stop(handle)
  end

  handle = uv.new_fs_event()
  local watch_dir = vim.fn.expand '~/.cache/hellwal'

  uv.fs_event_start(handle, watch_dir, {}, function(err, filename)
    if not err and filename == 'colourscheme.lua' then
      vim.defer_fn(reload, 100) -- Small debounce
    end
  end)
end

M.setup()
return M
