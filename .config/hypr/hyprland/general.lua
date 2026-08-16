hl.monitor({
	output = "HDMI-A-1",
	mode = "3840x2160@240",
	position = "0x0",
	scale = 1,
	bitdepth = 10,
	cm = "srgb",
	vrr = 0,
})

hl.monitor({
	output = "DP-1",
	mode = "2560x1440@144",
	position = "3840x0",
	scale = 1,
	bitdepth = 8,
	vrr = 0,
})

hl.layer_rule({ match = { namespace = "hyprpicker" }, no_anim = true })
hl.layer_rule({ match = { namespace = "selection" }, no_anim = true })

hl.config({
	input = {
		kb_layout = "us",
		follow_mouse = 1,
	},
	cursor = {
		default_monitor = "HDMI-A-1",
		no_hardware_cursors = true,
	},
})

local colors = require("hyprland-colours")

hl.config({
	general = {
		gaps_in = 3,
		gaps_out = 5,
		border_size = 3,
		col = {
			active_border = colors.active_border,
			inactive_border = colors.inactive_border,
		},
		resize_on_border = true,
		allow_tearing = false,
		layout = "dwindle",
	},
})

hl.config({
	decoration = {
		rounding = 8,
		active_opacity = 1.00,
		inactive_opacity = 1.00,
		shadow = {
			enabled = true,
			range = 4,
			render_power = 3,
			color = colors.shadow_color,
		},
		blur = {
			enabled = true,
			size = 7,
			passes = 3,
			vibrancy = 0.1696,
		},
	},
})

hl.config({ animations = { enabled = true } })

hl.curve("default", { type = "bezier", points = { { 0.12, 0.92 }, { 0.08, 1.0 } } })
hl.curve("wind", { type = "bezier", points = { { 0.12, 0.92 }, { 0.08, 1.0 } } })
hl.curve("overshot", { type = "bezier", points = { { 0.18, 0.95 }, { 0.22, 1.02 } } })
hl.curve("liner", { type = "bezier", points = { { 1, 1 }, { 1, 1 } } })

hl.animation({ leaf = "windows", enabled = true, speed = 5, bezier = "wind", style = "popin 60%" })
hl.animation({ leaf = "windowsIn", enabled = true, speed = 6, bezier = "overshot", style = "popin 60%" })
hl.animation({ leaf = "windowsOut", enabled = true, speed = 4, bezier = "overshot", style = "popin 60%" })
hl.animation({ leaf = "windowsMove", enabled = true, speed = 4, bezier = "overshot", style = "slide" })
hl.animation({ leaf = "layers", enabled = true, speed = 4, bezier = "default", style = "popin" })
hl.animation({ leaf = "fadeIn", enabled = true, speed = 7, bezier = "default" })
hl.animation({ leaf = "fadeOut", enabled = true, speed = 7, bezier = "default" })
hl.animation({ leaf = "fadeSwitch", enabled = true, speed = 7, bezier = "default" })
hl.animation({ leaf = "fadeShadow", enabled = true, speed = 7, bezier = "default" })
hl.animation({ leaf = "fadeDim", enabled = true, speed = 7, bezier = "default" })
hl.animation({ leaf = "fadeLayers", enabled = true, speed = 7, bezier = "default" })
hl.animation({ leaf = "workspaces", enabled = true, speed = 5, bezier = "overshot", style = "slidevert" })
hl.animation({ leaf = "border", enabled = true, speed = 1, bezier = "liner" })
hl.animation({ leaf = "borderangle", enabled = true, speed = 24, bezier = "liner", style = "loop" })

hl.config({
	dwindle = {
		preserve_split = true,
	},
})

hl.config({
	master = {
		new_status = "master",
	},
})

hl.config({
	misc = {
		force_default_wallpaper = -1,
		disable_hyprland_logo = false,
	},
})

hl.config({
	render = {
		cm_auto_hdr = 1,
		direct_scanout = 1,
	},
})
