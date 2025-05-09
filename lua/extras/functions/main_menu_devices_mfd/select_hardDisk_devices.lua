local fzf_lua = require("fzf-lua")
local extra_actions = require("extras.actions")
local utils = require("extras.utils")

_G.select_hardDisk_devices = function(opts)
	opts = opts or {}
	opts.prompt = "G&Devices Directories> "
	opts.fn_transform = function(x)
		return fzf_lua.utils.ansi_codes.magenta(x) -- Change to cyan for a beautiful color
	end
	-- Function to get the last part of the directory (alias), removing trailing slashes

	opts.actions = {
		-- ["default"] = function(selected)
		-- 	extra_actions.open_dir(selected)
		-- end,
		["default"] = function(selected)
			-- Extract the path from the selected string (regex improvement to capture valid paths)
			local selected_path = selected[1]:match("%(([^)]+)%)") -- Capture the path inside parentheses

			if not selected_path then
				-- If no path is found inside parentheses, just use the selected string itself
				selected_path = selected[1]
			end

			-- Check if selected path is a valid directory and is mounted
			if selected_path then
				-- Special handling for /dev/sda1, which is the root partition
				if selected_path == "/dev/sda1" then
					-- /dev/sda1 is mapped to the root filesystem (/)
					selected_path = "/"
					-- vim.cmd("silent !unalias cd")
					-- vim.cmd("silent !cd " .. selected_path)
					vim.cmd("cd " .. vim.fn.fnameescape(selected_path))
					-- vim.cmd("silent !alias cd='zoxide'")
					print("Changed directory to: " .. selected_path)
				else
					vim.cmd("cd " .. vim.fn.fnameescape(selected_path))
				end

				-- Check if the path exists as a directory
				-- if vim.fn.isdirectory(selected_path) == 1 then
				-- 	-- Use bash to invoke the native cd without using zoxide
				-- 	vim.cmd("silent !bash -c 'cd " .. selected_path .. " && exec bash'")
				-- 	print("Changed directory to: " .. selected_path)
				-- else
				-- 	-- If the path isn't a valid directory, check if it's a device like /dev/sda1
				-- 	-- Look for the mount point corresponding to the device
				-- 	local mount_point =
				-- 		vim.fn.system("findmnt --output TARGET --source " .. selected_path .. " --noheadings")
				--
				-- 	-- If the mount point is found, change directory to the mount point
				-- 	if mount_point ~= "" then
				-- 		-- Strip any extra whitespace
				-- 		mount_point = mount_point:gsub("^%s*(.-)%s*$", "%1")
				-- 		vim.cmd("silent !bash -c 'cd " .. mount_point .. " && exec bash'")
				-- 		print("Changed directory to mount point: " .. mount_point)
				-- 	else
				-- 		-- If no mount point is found, print an error message
				-- 		print("Could not determine the directory for: " .. selected_path)
				-- 	end
				-- end
			else
				print("Selected path is empty.")
			end
		end,
		-- Custom key binding for the 'Tab' key (using 'ctrl-v' + Tab for input mapping)
		["tab"] = function(selected, opts)
			local selected_path = utils.selected_path(selected)

			local tmux_session_name

			-- Handle root directory case
			if selected_path == "/dev/sda1" then
				selected_path = '/'
				tmux_session_name = "root"
			else
				tmux_session_name = utils.get_last_name(selected_path) -- Use directory name as tmux session name
			end

			if selected_path and vim.fn.isdirectory(selected_path) == 1 then
				-- Check if tmux is available

				-- Function to check if tmux is running
				local function is_tmux_running()
					local output = vim.fn.system("ps aux | grep tmux")
					return output:match("tmux") ~= nil -- Returns true if "tmux" is found, false otherwise
				end
				-- if vim.fn.executable "tmux" == 1 then
				if is_tmux_running() then
					-- print(
					--   "DEBUGPRINT[1]: fzf.lua:359: tmux_session_name="
					--     .. vim.inspect(tmux_session_name)
					-- )
					-- Check if the tmux session exists by using tmux has-session command
					local tmux_session_exists =
						vim.fn.system("tmux has-session -t " .. tmux_session_name .. ">/dev/null 2>&1")

					-- print(
					--   "DEBUGPRINT[1]: fzf.lua:376: tmux_session_exists="
					--     .. tmux_session_exists
					-- )
					vim.fn.system(
						"tmux new-session -d -s " .. tmux_session_name .. ' "cd ' .. selected_path .. '; bash"'
					)

					-- Attach to the tmux session
					vim.fn.system("tmux attach -t " .. tmux_session_name)

					-- Switch to the tmux client (optional)
					vim.fn.system("tmux switch-client -t " .. tmux_session_name)
				-- if tmux_session_exists then
				--   -- Check if tmux is running but user is detached
				--   vim.fn.system("tmux switch-client -t " .. tmux_session_name)
				--   print("Switched to tmux session: " .. tmux_session_name)
				-- ╭───────────────────────────────────────────────────────────────────╮
				-- │ Check if the tmux session is detached                             │
				-- ╰───────────────────────────────────────────────────────────────────╯
				-- NOTE: This is not working - because it needs to
				-- initiate a new tmux and then attach to it - which is not possible
				-- if tmux is already running or not running
				-- NOTE: Possible solution:
				-- 1. Initiate a new tmux from the root terminal
				-- 2. create a new buffer that runs the tmux and attach to it ane make the
				-- terminal alacritty or something else initiate
				-- the tmux

				-- local tmux_is_detached = vim.fn.system(
				--   "tmux list-sessions -F '#{session_name}:#{session_attached}' | grep -E '^"
				--     .. tmux_session_name
				--     .. ":[0]$' 2>/dev/null"
				-- ) ~= ""
				--
				-- print(
				--   "DEBUGPRINT[1]: fzf.lua:381: tmux_is_detached="
				--     .. vim.inspect(tmux_is_detached)
				-- )
				--
				-- elseif tmux_is_detached then --not working
				--   -- print("check " .. vim.fn.system "~/.config/nvim/lua/plugins/configs/fuzzy_finder/scripts-fzf/tmux.sh")
				--   -- vim.fn.system "./scripts-fzf/tmux.sh"
				--   -- vim.fn.system("tmux switch-client -t " .. tmux_session_name)
				--   print("Attached to tmux session: " .. tmux_session_name)
				-- else
				--   -- # Session doesn't exist, create a new one
				--   vim.fn.system(
				--     "tmux new-session -ds "
				--       .. tmux_session_name
				--       .. " -c "
				--       .. tmux_session_name
				--   )
				--   -- Optionally, attach to the session (this is usually the expected behavior)
				--   vim.fn.system("tmux switch-client -t " .. tmux_session_name)
				--   print(
				--     "Created and switched to new tmux session: " .. tmux_session_name
				--   )
				-- end
				else
					-- If tmux is not available, just change directory in Vim
					vim.cmd("cd " .. selected_path)
					-- print("Tmux Not Available CD to: " .. selected_path)
					-- local previous_dir = vim.fn.getcwd()
					-- If tmux is not running and session doesn't exist, create and attach
					-- print("Creating new tmux session '" .. tmux_session_name .. "'...")
					-- vim.fn.system(
					--   "tmux new-session -ds "
					--     .. vim.fn.shellescape(tmux_session_name)
					--     .. " -c "
					--     .. vim.fn.shellescape(previous_dir)
					-- )
					-- print("Attached to new tmux session '" .. tmux_session_name .. "'...")
					-- vim.fn.system(
					--   "tmux attach-session -t " .. vim.fn.shellescape(tmux_session_name)
					-- )
				end
			else
				-- If it's not a valid directory, just change the vim directory
				vim.cmd("cd " .. selected_path)
				print("Changed directory to: " .. selected_path)
			end

			if vim.g.neovide then
				vim.cmd("cd " .. selected_path)
				print("Changed directory to: " .. selected_path)
			end
		end,
	}

	local disks = {}
	if utils.is_windows() then
		local result = vim.fn.system([[
    wmic logicaldisk get Caption,Description,DriveType,DeviceID,MediaType
  ]])

		local function split(str, delimiter)
			local results = {}
			for match in (str .. delimiter):gmatch("(.-)" .. delimiter) do
				table.insert(results, match)
			end
			return results
		end

		-- Split the result into lines
		local lines = split(result, "\n")

		-- Insert the current directory entry with the dynamically set alias
		local usb_found = vim.fn.system([[
    wmic path Win32_USBHub get DeviceID
  ]])

		-- Check if the result is empty or contains no relevant data
		if usb_found == "" then
			print("USB not found")
		else
			-- If there are removable USB devices, show the result
			for _, line in ipairs(lines) do
				-- Only process non-empty lines and those that represent drives
				if line ~= "" and line:match("^[A-Za-z]:") then
					local drive, description = line:match("([A-Za-z]):%s*(%S+)")
					if drive and description then
						-- Choose the drive letter as alias
						local alias = drive
						table.insert(disks, { path = drive .. ":", alias = alias })
					end
				end
			end
		end
	else
		local user = utils.get_user_home()
		if not user then
			print("Error could not determine the user!: ", user)
			return
		end

		local command = "lsblk -o NAME,SIZE,FSTYPE,MOUNTPOINT -nr | grep '^sd'"

		-- Start the process to run the command
		local handle = io.popen(command .. " 2>&1")
		local output = handle:read("*a")
		handle:close()

		-- Ensure the result is not empty before proceeding
		for line in output:gmatch("[^\r\n]+") do
			local name, size, fstype, mountpoint = line:match("(%S+)%s+(%S+)%s+(%S*)%s*(.*)")

			if name and size then
				-- Construct the device path
				local device = "/dev/" .. name

				-- Only include /dev/sda1
				if device == "/dev/sda1" then
					-- Ensure that the filesystem type is set to "unknown" if it's empty
					fstype = fstype ~= "" and fstype or "unknown"

					-- Insert only /dev/sda1 into the disks table
					table.insert(disks, { path = device, size = size, fstype = fstype })
				end
			end
		end
	end

	local max_name_len, max_size_len = 0, 0

	local function calculate_padding(list)
		for _, link in ipairs(list) do
			if list.alias then
				max_name_len = math.max(max_name_len, #link.path)
				max_size_len = math.max(max_size_len, #link.alias)
			else
				max_name_len = math.max(max_name_len, #link.fstype)
				max_size_len = math.max(max_size_len, #link.fstype)
			end
		end
	end
	--
	calculate_padding(disks)
	--
	local fzf_entries = {}
	for _, disk in ipairs(disks) do
		if disk.alias then
			local path = "(" .. disk.path .. ")"
			local padded_name = string.format("%-" .. max_name_len .. "s", path)
			local padded_desc = string.format("%-" .. max_size_len .. "s", disk.alias)
			table.insert(fzf_entries, string.format("%s │ %s ", padded_desc, padded_name))
		else
			local padded_name = string.format("%-" .. max_name_len .. "s", disk.fstype)
			local padded_desc = string.format("%-" .. max_size_len .. "s", disk.size)
			local url = string.format("%-" .. #disk.path + 2 .. "s", "(" .. disk.path .. ")") -- +2 for the parentheses
			table.insert(fzf_entries, string.format("%s │ %s │ %s", padded_name, padded_desc, url))
		end
	end

	-- Execute fzf with the list of hard disks
	fzf_lua.fzf_exec(fzf_entries, opts)
end
