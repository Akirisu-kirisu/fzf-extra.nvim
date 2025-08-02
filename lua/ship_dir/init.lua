local H = require("ship_dir.handlers")

local M = {}

function M.setup()

	local commands = {
		"DirGlobal",
		"DirLocal",
		"DirDepth",
		"OpenFiles",
		"RecentDir",
		"HiddenDir",
		"HiddenFiles",
		"GitCommits",
		"OptsMenu",
		"Packages",
		"OptsDevices",
		"Devices",
		"HardDisk",
		"Api",
		"Links",
		"CmdLine",
		"Commands",
		"NvimPlugins",
		"GitRepo",
		"DirHistory",
	}

	for _, cmd in ipairs(commands) do
		if type(H[cmd]) == "function" then
			vim.api.nvim_create_user_command(cmd, H[cmd], {})
		else
			vim.schedule(function()
				vim.notify(("[myplugin] Missing function for :%s"):format(cmd), vim.log.levels.WARN)
			end)
		end
	end
end

return M
