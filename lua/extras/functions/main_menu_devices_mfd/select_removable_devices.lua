local fzf_lua = require("fzf-lua")
local extra_actions = require("extras.actions")

_G.select_removable_devices = function(opts)
	opts = opts or {}
	opts.prompt = "G&Devices Directories> "
	opts.fn_transform = function(x)
		return fzf_lua.utils.ansi_codes.magenta(x) -- Change to cyan for a beautiful color
	end
	-- Function to get the last part of the directory (alias), removing trailing slashes

	opts.actions = {
		["default"] = function(selected)
			extra_actions.open_dir(selected)
		end,
		-- ["default"] = function(selected)
		-- 	-- Extract the path from the selected string (regex improvement to capture valid paths)
		-- 	local selected_path = selected[1]:match("%(([^)]+)%)") -- This captures the path inside parentheses
		-- 	if not selected_path then
		-- 		-- If no path is found inside parentheses, just use the selected string itself
		-- 		selected_path = selected[1]
		-- 	end
		--
		-- 	if selected_path and vim.fn.isdirectory(selected_path) == 1 then
		-- 		vim.cmd("cd " .. selected_path)
		-- 		print("Changed directory to: " .. selected_path)
		-- 	else
		-- 		print("Could not determine the directory.")
		-- 	end
		-- end,
		-- Custom key binding for the 'Tab' key (using 'ctrl-v' + Tab for input mapping)
		["tab"] = function(selected, opts)
			extra_actions.open_dir_tmux(selected)
		end,
	}

	-- Initialize directories list (use a global variable to store them)
	-- local current_dir = vim.fn.getcwd()
	--
	-- -- Dynamically set the alias for the current directory to its name
	-- local current_dir_name = vim.fn.fnamemodify(current_dir, ":t") -- This gets the last part of the directory path (i.e., the name of the directory)
	-- local current_dir_name = current_dir_name .. " (" .. current_dir .. ")"

	_G.directories_devices = _G.directories_devices or {}

	-- local result =
	--   vim.fn.system 'df -h | grep "/dev" | grep -v "tmpfs" | awk \'{print $1 " - " $6}\''

	if package.config:sub(1, 1) == "\\" then
		-- Windows logic
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
						table.insert(_G.directories_devices, { path = drive .. ":", alias = alias })
					end
				end
			end
		end
	else
		local result = vim.fn.system([[
df -hP | awk '$1 ~ /^\/dev/ && $1 !~ /tmpfs/ && $6 != "/" {print $1 " - " $6}'
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

		local usb_found = vim.fn.system("lsblk -o NAME,MOUNTPOINT | grep '/media\\|/mnt' | grep -v '/root'")

		-- Check if the result is empty or contains no relevant data
		if usb_found == "" then
			print("usb not found")
		else
			-- If there are removable USB devices, show the result
			for _, line in ipairs(lines) do
				-- Only process non-empty lines
				if line ~= "" then
					-- Match the device and mount point, splitting on the hyphen
					local device, mount_point = line:match("([%w/]+)%s*-%s*(.+)")
					if device and mount_point then
						-- Choose the last word from the device string as alias
						local alias = device:match("([^/]+)$")
						table.insert(_G.directories_devices, { path = mount_point, alias = alias })
					end
				end
			end
		end
	end

	-- Define your predefined directories (same as before)
	local unique_directories = {}
	local seen = {}

	-- List subdirectories and process them
	for _, dir in ipairs(_G.directories_devices) do
		-- Add the directory itself if not seen yet
		if not seen[dir.path] then
			seen[dir.path] = true
			table.insert(unique_directories, dir)
		end
	end

	-- Update the global directory list with the filtered, unique entries
	_G.directories_devices = unique_directories

	-- Transform the directories into a format suitable for fzf
	-- local fzf_list = {}
	-- for _, dir in ipairs(_G.directories_devices) do
	--   -- Format: alias (path)
	--   table.insert(fzf_list, "" .. " " .. dir.alias .. " (" .. dir.path .. ")")
	-- end

	-- Better! Transform the directories & speed it up into a format suitable for fzf
	local function fzf_lists(fzf_cb)
		coroutine.wrap(function()
			local co = coroutine.running()

			for _, dir in ipairs(_G.directories_devices) do
				-- Format: alias (path)
				vim.schedule(function()
					-- local name = "" .. " " .. dir.alias .. " (" .. dir.path .. ")"
					local name_width = 30
					local path_width = 80

					-- Function to pad string to a specific width
					local function pad_string(str, width, alignment)
						if alignment == "left" then
							return string.format("%-" .. width .. "s", str) -- Left-align
						elseif alignment == "right" then
							return string.format("%" .. width .. "s", str) -- Right-align
						else
							return string.format("%-" .. width .. "s", str) -- Default to left-align
						end
					end

					-- Prepare the name, path, and timestamp with padding
					local name = " " .. dir.alias

					-- Trim dir_name if it's too long
					local function trim_string(str, max_length)
						if #str > max_length then
							return string.sub(str, 1, max_length - 3) .. "..." -- Trim and add ellipsis
						else
							return str
						end
					end
					name = trim_string(name, name_width)

					-- Trim the path if it's too long and add parentheses
					local function trim_path(str, max_length)
						if #str > max_length then
							return "(" .. string.sub(str, 1, max_length - 3) .. "..." .. ")" -- Trim, add ellipsis, and wrap in parentheses
						else
							return "(" .. str .. ")" -- Wrap the path in parentheses
						end
					end
					local path = trim_path(dir.path, path_width)

					-- Apply padding for each column
					local formatted_name = pad_string(name, name_width, "left")
					local formatted_path = pad_string(path, path_width, "left")

					-- Combine the formatted parts with a separator (e.g., space) between columns
					local formatted_output = formatted_name .. formatted_path

					fzf_cb(formatted_output, function()
						coroutine.resume(co)
					end)
				end)

				coroutine.yield()
			end
			fzf_cb()
		end)()
	end

	-- Execute fzf with the custom directory list
	fzf_lua.fzf_exec(fzf_lists, opts)
end
