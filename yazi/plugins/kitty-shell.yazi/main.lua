local get_context = ya.sync(function()
	local function file(item)
		if not item then return nil end
		return {
			path = tostring(item.url.path),
			url = tostring(item.url),
			dir = item.url.parent and tostring(item.url.parent.path) or "",
			dir_url = item.url.parent and tostring(item.url.parent) or "",
		}
	end

	local function files(set)
		local result = {}
		for _, item in pairs(set) do
			result[#result + 1] = file(item)
		end
		return result
	end

	local function tab(value)
		return { hovered = file(value.current.hovered), selected = files(value.selected) }
	end

	local idx, count = cx.tabs.idx, #cx.tabs
	local next_tab = cx.tabs[idx % count + 1]
	local prev_tab = cx.tabs[(idx - 2 + count) % count + 1]
	return {
		cwd = tostring(cx.active.current.cwd.path),
		current = tab(cx.active),
		next_tab = tab(next_tab),
		prev_tab = tab(prev_tab),
		yanked = files(cx.yanked),
	}
end)

local function command_args(context)
	local args = {}
	local function add_file(file)
		for _, field in ipairs { "path", "url", "dir", "dir_url" } do
			args[#args + 1] = file and file[field] or ""
		end
	end
	local function add_tab(tab)
		add_file(tab.hovered)
		args[#args + 1] = tostring(#tab.selected)
		for _, file in ipairs(tab.selected) do add_file(file) end
	end
	add_tab(context.current)
	add_tab(context.next_tab)
	add_tab(context.prev_tab)
	args[#args + 1] = tostring(#context.yanked)
	for _, file in ipairs(context.yanked) do add_file(file) end
	return args
end

return {
	entry = function(_, job)
		local mode = job.args[1]
		if mode ~= "shell" and mode ~= "command" then return end

		local context = get_context()
		local home = os.getenv("HOME")
		local config = os.getenv("XDG_CONFIG_HOME") or (home .. "/.config")
		local bridge = config .. "/yazi/kitty-bridge.sh"
		local args = { bridge, mode }
		if mode == "command" then
			for _, value in ipairs(command_args(context)) do args[#args + 1] = value end
		end
		local output, err = Command("bash"):arg(args):cwd(context.cwd):output()
		if err or not output or not output.status.success then
			ya.notify {
				title = "Kitty launch failed",
				content = err and tostring(err) or (output.stderr ~= "" and output.stderr or "Check Kitty remote control and kitten"),
				level = "error",
			}
		end
	end,
}
