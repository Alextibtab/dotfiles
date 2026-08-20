local smw = require("hyprland.plugins")

hl.bind("SUPER + Return", hl.dsp.exec_cmd("ghostty"))
hl.bind("SUPER + Y", hl.dsp.exec_cmd("ghostty -e /home/tibtab/.cargo/bin/spotify_player"))
hl.bind("SUPER + W", hl.dsp.window.close())
hl.bind("SUPER + M", hl.dsp.exit())
hl.bind("SUPER + Space", hl.dsp.exec_cmd("wofi --conf ~/.config/wofi/config --style ~/.cache/hellwal/wofi.css"))
hl.bind("SUPER + E", hl.dsp.exec_cmd("thunar"))
hl.bind("SUPER + V", hl.dsp.window.float({ action = "toggle" }))

hl.bind("SUPER + S", hl.dsp.workspace.toggle_special("scratchpad"))
hl.bind("SUPER + ALT + S", hl.dsp.window.move({ workspace = "special:scratchpad" }))

hl.bind("SUPER + H", hl.dsp.focus({ direction = "l" }))
hl.bind("SUPER + J", hl.dsp.focus({ direction = "d" }))
hl.bind("SUPER + K", hl.dsp.focus({ direction = "u" }))
hl.bind("SUPER + L", hl.dsp.focus({ direction = "r" }))

hl.bind("SUPER + KP_Add", hl.dsp.exec_cmd("waypaper"))

for i = 1, smw.get_amount_of_workspaces() do
	local n = tostring(i)
	hl.bind("SUPER + " .. n, smw.workspace(n))
	hl.bind("SUPER + SHIFT + " .. n, smw.move_to_workspace_silent(n))
end

hl.bind("SUPER + mouse_down", smw.cycle_workspaces("prev"))
hl.bind("SUPER + mouse_up", smw.cycle_workspaces("next"))

hl.bind("SUPER + mouse:272", hl.dsp.window.drag(), { mouse = true })
hl.bind("SUPER + mouse:273", hl.dsp.window.resize(), { mouse = true })

hl.bind("SUPER + F", hl.dsp.window.fullscreen())

hl.bind("SUPER + SHIFT + P", hl.dsp.exec_cmd("hyprshot -m output --clipboard-only"))
hl.bind("SUPER + CTRL + P", hl.dsp.exec_cmd("hyprshot -m region --clipboard-only"))
hl.bind("SUPER + P", hl.dsp.exec_cmd("hyprshot -m window --clipboard-only"))
