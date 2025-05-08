local fzf_lua = require("fzf-lua")
local utils = require("extras.utils")

_G.select_hardDisk = function(opts)
	opts = opts or {}
	opts.prompt = "Hard Disks> "

	opts.actions = {
		["default"] = {
			fn = function(selected)
				-- Do something with the selected disk, if needed
			end,
			exec_silent = true,
		},
	}

	local user = utils.get_user_home()
	if not user then
		print("Error could not determine the user!: ", user)
		return
	end

	-- Prepare the command to check if sudo requires a password
	local check_sudo_command = "sudo -n true 2>&1"

	-- Run the command and capture the output
	local handle = io.popen(check_sudo_command)
	local output = handle:read("*a")
	print('DEBUGPRINT[220]: test.lua:28: output=' .. vim.inspect(output))
	handle:close()

	-- Check if the output contains "password for" (indicating a password is required)
	if output:match("%[sudo%] password for " .. user) then
		print('DEBUGPRINT[219]: test.lua:32: output:match=' .. vim.inspect(output:match(("%[sudo%] password for " .. user))))
		-- Prompt the user to enter the sudo password
		print("Please enter your sudo password:")

		-- Get the password input from the user
		local password = io.read("*l") -- read password from user input
		print('DEBUGPRINT[218]: test.lua:37: password=' .. vim.inspect(password))

		-- Now prepare the fdisk command with the provided password
		local fdisk_command = "echo " .. password .. " | sudo -S fdisk -l | grep '^/dev/'"

		-- Run the fdisk command with sudo
		handle = io.popen(fdisk_command)
		output = handle:read("*a")
		handle:close()
	else
		-- If no password is required, run the fdisk command normally
		local fdisk_command = "sudo fdisk -l | grep '^/dev/'"
		handle = io.popen(fdisk_command)
		output = handle:read("*a")
		handle:close()
	end

	-- Parse the output and collect the disk information
	local disks = {}
	for line in output:gmatch("[^\r\n]+") do
		local device, size, type = line:match("(%S+)%s+.*%s+%S+%s+([%d%.]+%s?[GiB|MiB|KiB]+)%s+(%S+)")

		if device and size and type then
			table.insert(disks, { name = device, size = size, type = type })
		end
	end

	-- Prepare entries for FZF with proper alignment
	local fzf_entries = {}
	for _, disk in ipairs(disks) do
		table.insert(fzf_entries, string.format("%s │ %s │ %s", disk.name, disk.size, disk.type))
	end

	-- Execute fzf with the list of hard disks
	fzf_lua.fzf_exec(fzf_entries, opts)
end
