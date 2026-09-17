local wezterm = require("wezterm")

-- wezterm.on("format-tab-title", function(tab)
-- 	local pane = tab.active_pane
-- 	local title = pane.title
-- 	if pane.domain_name then
-- 		-- title = title .. " (" .. pane.domain_name .. ")"
-- 		title = " " .. pane.domain_name .. " "
-- 	end
-- 	return title
-- end)

local config = {}

config.font = wezterm.font("JetBrainsMonoHangul Nerd Font")
config.font_size = 13.0

config.window_padding = {
	top = 2,
	right = 4,
	bottom = 0,
	left = 4,
}

config.initial_cols = 160
config.initial_rows = 40

config.default_cursor_style = "SteadyBar"

config.scrollback_lines = 10000

config.default_prog = { "bash", "--login", "-c", "exec ~/.local/bin/fish" }

config.color_scheme = "Vs Code Dark+ (Gogh)"

-- config.unix_domains = {
-- 	{
-- 		name = "localhost",
-- 	},
-- }

-- local status, ssh_config = pcall(require, "ssh")
-- if status then
-- 	config.ssh_domains = ssh_config
-- else
-- 	config.ssh_domains = {}
-- end

return config
