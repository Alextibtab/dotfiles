hl.window_rule({ match = { class = ".*" }, suppress_event = "maximize" })

hl.window_rule({
	match = { class = "^$", title = "^$", xwayland = true, float = true, fullscreen = false, pin = false },
	no_focus = true,
})

hl.window_rule({ match = { class = "^(xwaylandvideobridge)$" }, opacity = "0.0 override" })
hl.window_rule({ match = { class = "^(xwaylandvideobridge)$" }, no_anim = true })
hl.window_rule({ match = { class = "^(xwaylandvideobridge)$" }, no_initial_focus = true })
hl.window_rule({ match = { class = "^(xwaylandvideobridge)$" }, max_size = { 1, 1 } })
hl.window_rule({ match = { class = "^(xwaylandvideobridge)$" }, no_blur = true })

hl.window_rule({ match = { class = "jetbrains-.*", title = "splash", float = true }, center = true })
hl.window_rule({ match = { class = "jetbrains-.*", title = "splash", float = true }, no_focus = true })

hl.window_rule({ match = { class = "jetbrains-.*", title = "win.*", float = true }, no_focus = true })

hl.window_rule({ match = { class = "jetbrains-.*", float = true }, no_blur = true })
hl.window_rule({ match = { class = "jetbrains-.*", float = true }, no_initial_focus = true })
hl.window_rule({ match = { class = "jetbrains-.*", float = true }, opacity = "1 override 1 override 1" })
hl.window_rule({ match = { class = "jetbrains-.*" }, opacity = "1 override 1 override 1" })

hl.window_rule({ match = { class = "firefox-developer-edition" }, opacity = "1 override 1 override 1" })


