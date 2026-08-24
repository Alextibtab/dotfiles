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

hl.window_rule({ match = { class = "librewolf" }, opacity = "1 override 1 override 1" })
hl.window_rule({ match = { class = "discord" }, opacity = "1 override 1 override 1" })
hl.window_rule({ match = { class = "flipperui" }, opacity = "1 override 1 override 1" })
hl.window_rule({ match = { class = "winboat" }, opacity = "1 override 1 override 1" })

hl.window_rule({ match = { title = "mal-tui" }, opacity = "1 override 1 override 1" })

hl.window_rule({ match = { initial_title = "Steam Big Picture Mode" }, monitor = "2" })

-- Bitwarden (Chrome app): float, center, and size at a small fixed size. The
-- class is unique to the Chrome app (chrome-<ext-id>-Default), so browser
-- tabs aren't affected. Matching on class works here because initialClass is
-- stable, unlike the title which only becomes "Bitwarden" after the app loads
-- (see hyprwm/Hyprland#3835).
hl.window_rule({
	match = { class = "chrome-nngceckbapebfimnlniiiahkandclblb-Default" },
	float = true,
	center = true,
	size = "900 700",
})

-- Migaku (Chrome app): same treatment as Bitwarden, but wider and taller.
hl.window_rule({
	match = { class = "chrome-dmeppfcidcpcocleneopiblmpnbokhep-Default" },
	float = true,
	center = true,
	size = "1400 900",
})

-- System Updates terminal (quickshell bar): launch it floated, centered, and
-- at a fixed non-fullscreen size instead of tiled. Matches the ghostty window
-- the bar spawns with --title "System Updates" (initial_title, so normal
-- terminals that later adopt that title are not affected).
hl.window_rule({
	match = { initial_title = "^(System Updates)$" },
	float = true,
	center = true,
	size = "1500 1000",
})
