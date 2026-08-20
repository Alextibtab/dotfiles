package.path = package.path .. ";./?.lua;./?/init.lua"
local smw = require("plugins.split-monitor-workspaces")

smw.setup({
	workspace_count = 5,
	enable_notifications = false,
	enable_persistent_workspaces = true,
	monitor_priority = { "HDMI-A-1", "DP-1" },
})

return smw
