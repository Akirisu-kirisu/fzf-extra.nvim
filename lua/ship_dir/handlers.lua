local M = {}

-- Lazy loader for utils

local function utils()
	return require("ship_dir.utils")
end

local function ui()
	return require("ship_dir.ui")
end

local function S()
	return require("ship_dir.directories")
end

M.DirGlobal = function(opts)
	utils().last_selected(M.DirGlobal)
	local fzf_lua = require("fzf-lua")
	opts = opts or {}
	opts.prompt = "Global Directories> "
	opts.fn_transform = function(x)
		return fzf_lua.utils.ansi_codes.magenta(x) -- Change to cyan for a beautiful color
	end

	opts.actions = {
		["ctrl-y"] = {
			fn = function(selected)
				utils().captures_parentheses_copy(selected)
			end,
			exec_silent = true,
		},
		["default"] = {
			fn = function(selected)
				utils().open_dir(selected)
			end,
			-- exec_silent = true,
		},
		-- Custom key binding for the 'Tab' key (using 'ctrl-v' + Tab for input mapping)
		["tab"] = function(selected)
			utils().open_dir_tmux(selected)
		end,
	}

	utils().get_current_dir(S().directories)
	-- --
	utils().subdirs(S().directories)
	-- --
	local function fzf_lists(fzf_cb)
		coroutine.wrap(function()
			local co = coroutine.running()
			ui().calculate_padding(S().directories)
			for _, dir in ipairs(S().directories) do
				-- local timestamp = utils.get_timestamp(dir.path) cost performance

				local output = ui().format_directory_output(dir, ui().max_path_len)

				fzf_cb(output, function()
					coroutine.resume(co)
				end)

				coroutine.yield()
			end

			-- Signal end of list
			fzf_cb()
		end)()
	end
	-- Main loop to process directories
	-- Execute fzf with the custom directory list
	fzf_lua.fzf_exec(fzf_lists, opts)
end


M.DirLocal = function(opts)
	local fzf_lua = require("fzf-lua")
	utils().last_selected(M.DirLocal)
	opts = opts or {}
	opts.prompt = "Local Directories> "
	opts.fn_transform = function(x)
		return fzf_lua.utils.ansi_codes.green(x)
	end

	opts.actions = {
		["default"] = {
			fn = function(selected)
				utils().open_dir(selected)
			end,
			exec_silent = true,
		},
		["ctrl-s"] = {
			fn = function(selected)
				utils().horizontal(selected)
			end,
		},
		["alt-s"] = {
			fn = function()
				M.HiddenDir()
			end,
		},
		["alt-v"] = {
			fn = function(selected)
				utils().vertical(selected)
			end,
		},
		["ctrl-o"] = {
			fn = function()
				vim.cmd("Oil ")
			end,
		},
		["tab"] = function(selected)
			utils().open_dir_tmux(selected)
		end,
		-- ["alt-m"] = {
		-- 	fn = function(selected)
		-- 		_G.select_directory_global_mfe()
		-- 	end,
		-- 	exec_silent = true,
		-- },
		["alt-m"] = {
			fn = function()
				M.RecentDir()
			end,
		},

		["alt-d"] = {
			fn = function()
				M.DirDepth()
			end,
			exec_silent = true,
		},
		["alt-e"] = {
			fn = function()
				M.OpenFiles()
			end,
		},
	}

	local fzf_list = {}
	local fd_command = "fd --type d --exclude node_modules --max-depth 1 ."

	-- Execute the 'fd' command and capture the output
	local output = vim.fn.systemlist(fd_command)

	-- Iterate over the directories found by 'fd' and prepare them for fzf
	for _, subdir in ipairs(output) do
		if vim.fn.isdirectory(subdir) == 1 then
			local lastname = utils().get_last_name(subdir)
			local path = subdir

			table.insert(fzf_list, { alias = lastname, path = path })
		end
	end

	ui().calculate_padding(fzf_list)
	local formatted_list = {}
	for _, subdir in ipairs(fzf_list) do
		local formatted_ui = ui().format_directory_output(subdir, ui().max_path_len)
		table.insert(formatted_list, formatted_ui)
	end

	fzf_lua.fzf_exec(formatted_list, opts)
end

M.DirDepth = function(opts)
	local fzf_lua = require("fzf-lua")
	utils().last_selected(M.DirDepth)
	opts = opts or {}
	opts.prompt = "Depth Directories> "
	opts.fn_transform = function(x)
		return fzf_lua.utils.ansi_codes.magenta(x) -- Change to cyan for a beautiful color
	end

	opts.actions = {
		["ctrl-y"] = {
			fn = function(selected)
				utils().captures_parentheses_copy(selected)
			end,
			exec_silent = true,
		},
		["default"] = {
			fn = function(selected)
				utils().open_oil(selected)
			end,
		},
		["ctrl-s"] = {
			fn = function(selected)
				utils().horizontal(selected)
			end,
		},
		["alt-v"] = {
			fn = function(selected)
				utils().vertical(selected)
			end,
		},
		["ctrl-o"] = {
			fn = function()
				vim.cmd("Oil ")
			end,
		},
		["alt-s"] = {
			fn = function()
				M.HiddenDir()
			end,
		},
		-- Custom key binding for the 'Tab' key (using 'ctrl-v' + Tab for input mapping)
		["tab"] = function(selected)
			utils().open_dir_tmux(selected)
		end,
		["alt-m"] = {
			fn = function()
				M.RecentDir()
			end,
		},
		["alt-d"] = {
			fn = function()
				M.DirLocal()
			end,
			exec_silent = true,
		},
		["alt-e"] = function()
			M.OpenFiles()
		end,
	}

	local fzf_list = {}
	local fd_command = "fd --type d --exclude node_modules --max-depth 4 ."

	-- Execute the 'fd' command and capture the output
	local output = vim.fn.systemlist(fd_command)

	-- Iterate over the directories found by 'fd' and prepare them for fzf
	for _, subdir in ipairs(output) do
		if vim.fn.isdirectory(subdir) == 1 then
			local lastname = utils().get_last_name(subdir)
			local path = subdir

			table.insert(fzf_list, { alias = lastname, path = path })
		end
	end

	ui().calculate_padding(fzf_list)
	local formatted_list = {}
	for _, subdir in ipairs(fzf_list) do
		local formatted_ui = ui().format_directory_output(subdir, ui().max_path_len)
		table.insert(formatted_list, formatted_ui)
	end

	fzf_lua.fzf_exec(formatted_list, opts)
end

M.OpenFiles = function(opts)
	local fzf_lua = require("fzf-lua")
	utils().last_selected(M.OpenFiles)
	opts = opts or {}
	opts.prompt = "Files> "
	-- opts.fn_transform = function(x)
	--   return fzf_lua.utils.ansi_codes.magenta(x)
	-- end
	opts.actions = {
		["default"] = function(selected)
			vim.cmd("e " .. selected[1]) -- 'e' is the command to edit a file
		end,

		["alt-a"] = function(selected)
			local file = selected[1]
			local os_name = vim.loop.os_uname().sysname

			-- Open the file based on OS
			if os_name == "Darwin" then -- macOS
				os.execute("open " .. file)
			elseif os_name == "Linux" then -- Linux
				os.execute("xdg-open " .. file)
			elseif os_name == "Windows_NT" then -- Windows
				os.execute("start " .. file)
			else
				print("Unsupported OS")
			end
		end,

		["alt-m"] = function()
			M.DirLocal()
		end,
	}

	fzf_lua.fzf_exec("fd --type f", opts) -- fd command for files
end

M.RecentDir = function()
	local fzf_lua = require("fzf-lua")
	-- Format the list with aliases
	local formatted = {}
	local seen_paths = {}

	for _, entry in ipairs(S().directories_temp_back or {}) do
		if not seen_paths[entry.path] then
			table.insert(formatted, string.format("[%d] %s", entry.alias, entry.path))
			seen_paths[entry.path] = true
		end
	end


	-- Picker options
	local opts = {
		prompt = "Recent Directories> ",
		fn_transform = function(x)
			return fzf_lua.utils.ansi_codes.cyan(x) -- cyan = more readable
		end,
		actions = {
			["default"] = function(selected)
				local line = selected[1]
				local path = line:match("%] (.+)$")
				if path then
					vim.cmd("cd " .. vim.fn.fnameescape(path))
					print("Changed directory to: " .. path)
				end
			end,
		},
	}
	fzf_lua.fzf_exec(formatted, opts)
end

M.HiddenDir = function(opts)
	local fzf_lua = require("fzf-lua")
	utils().last_selected(M.HiddenDir)
	opts = opts or {}
	opts.prompt = "Hidden Directories> "
	opts.fn_transform = function(x)
		return fzf_lua.utils.ansi_codes.magenta(x)
	end
	opts.actions = {
		["default"] = function(selected)
			vim.cmd("cd " .. selected[1])
			-- print('DEBUGPRINT[70]: handlers.lua:203: selected=' .. vim.inspect(selected[1]))
			vim.cmd("Oil " .. selected[1])
		end,

		["alt-s"] = function()
			M.HiddenFiles()
		end,

		["alt-m"] = {
			fn = function()
				M.DirGlobal()
			end,
		},

		["tab"] = function(selected)
			utils().open_dir_tmux(selected)
		end,
	}
	-- Modify the fd command to correctly search hidden directories and exclude .git
	-- Also, ensure to include directories that are hidden (starting with a dot)
	-- fzf_lua.fzf_exec("fd --type d --hidden --exclude node_modules '.*' ! -name '.' --absolute-path --max-depth 1 .", opts)
	fzf_lua.fzf_exec("find . -maxdepth 1 -type d -name '.*' ! -name '.' -exec realpath {} \\;", opts)
end

M.HiddenFiles = function(opts)
	utils().last_selected(M.HiddenFiles)
	opts = opts or {}
	opts.prompt = "Hidden Files> "
	opts.fn_transform = function(x)
		return require("fzf-lua.utils").ansi_codes.magenta(x)
	end

	opts.actions = {
		["default"] = function(selected)
			vim.cmd("edit " .. vim.fn.fnameescape(selected[1]))
		end,

		["alt-s"] = function()
			M.HiddenDir()
		end,

		["alt-m"] = {
			fn = function()
				M.DirGlobal()
			end,
		},

		["tab"] = function(selected)
			utils().open_file_tmux(selected)
		end,
	}

	-- Use `find` to get hidden files (exclude `.` and `..`, use realpath for clarity)
	local find_cmd = "find . -maxdepth 1 -type f -name '.*' -exec realpath {} \\;"
	require("fzf-lua").fzf_exec(find_cmd, opts)
end

M.GitCommits = function(opts)
	local fzf_lua = require("fzf-lua")
	utils().last_selected(M.GitCommits)
	opts = opts or {}

	opts.prompt = "Commits> "
	opts.fn_transform = function(x)
		return fzf_lua.utils.ansi_codes.yellow(x)
	end

	opts.preview = "git show --color=always {1}"
	opts.winopts = {
		preview = {
			layout = "vertical", -- or "horizontal"
			vertical = "right:70%", -- 70% of width on the right
			wrap = true,
		},
	}

	opts.silent = true -- suppress deprecation warnings

	opts.actions = {
		["default"] = function(selected)
			local commit_hash = selected[1]:match("^%w+")
			if commit_hash then
				-- Open a new tab and display the full commit details using bat with proper syntax highlighting
				-- vim.cmd("tabnew")  -- Open a new tab
				-- Use git show to display the full commit with the diff and pipe it to bat for proper syntax highlighting
				vim.cmd("term git show " .. commit_hash .. " | bat --language=diff --pager=never --style=full") -- Show full commit details including message and diff
			end
		end,
		["tab"] = function(selected)
			local commit_hash = selected[1]:match("^%w+")
			if commit_hash then
				vim.cmd("DiffviewOpen " .. commit_hash)
			end
		end,
	}

	local git_log_cmd =
		"git log --pretty=format:'%C(yellow)%h %Cgreen%ad %Cblue%an%Creset %s' --date=short --color=always"
	fzf_lua.fzf_exec(git_log_cmd, opts)
end

M.OptsMenu = function()
	local fzf_lua = require("fzf-lua")
	utils().last_selected(M.OptsMenu)
	local opts = {
		prompt = "Select Option> ",
		fzf_opts = {
			["--preview"] = "echo {}",
		},
		actions = { -- Correct key here
			["default"] = function(selected)
				-- If "Git Repos" is selected, call the fzf_dirs_git function to open another fzf
				if selected[1] == "Git Repos" then
					M.GitRepo()
				elseif selected[1] == "Plugins" then
					-- If "Links" is selected, you can add code to handle that case here
					M.NvimPlugins()
				elseif selected[1] == "Terminal Commands" then
					--   -- If "Links" is selected, you can add code to handle that case here
					M.Commands()
				elseif selected[1] == "Neovim Cmdline" then
					--   -- If "Links" is selected, you can add code to handle that case here
					M.CmdLine()
				elseif selected[1] == "Links" then
					--   -- If "Links" is selected, you can add code to handle that case here
					M.Links()
				elseif selected[1] == "API" then
					--   -- If "Links" is selected, you can add code to handle that case here
					M.Api()
				elseif selected[1] == "Packages" then
					-- If "Links" is selected, you can add code to handle that case here
					M.Packages()
				end
			end,
		},
	}
	-- Define the choices for the fzf menu
	local choices = { "Plugins", "Git Repos", "Links", "Terminal Commands", "Neovim Cmdline", "API", "Packages" }

	-- Open fzf for selecting between "Links" or "Git Repos"
	fzf_lua.fzf_exec(choices, opts)
end

M.Packages = function(opts)
	local fzf_lua = require("fzf-lua")
	utils().last_selected(M.Packages)
	opts = opts or {}
	opts.prompt = "Packages> " -- typo fixed: promt -> prompt

	local scratch_pad = ""
	opts.actions = {
        ["alt-m"] = {
			fn = function()
				M.OptsMenu()
			end,
			exec_silent = true,
		},
		["default"] = {
			fn = function(selected)
				-- Get the selected dependency name (strip version info)
				local dep = selected[1]:match("([^:]+)")

				local package_json = vim.fn.getcwd() .. "/package.json"
				local rg_cmd = "rg --line-number '\"" .. dep .. '"\' "' .. package_json .. '"'

				local handle = io.popen(rg_cmd)
				local result = handle and handle:read("*a") or ""
				if handle then
					handle:close()
				end

				local line_number = result:match("^(%d+):")
				line_number = tonumber(line_number)

				if line_number then
					vim.cmd("edit " .. package_json)
					vim.fn.cursor({ line_number, 1 })
				else
					print("Dependency not found in package.json:", dep)
				end
			end,
		},
		["tab"] = {
			fn = function(selected)
				local dep = selected[1]
				-- Remove the version number, ^, and colon
				dep = dep:match("([%a%-]+)") -- This will match the dependency name before any version info
				if scratch_pad == "" then
					scratch_pad = dep
				else
					scratch_pad = scratch_pad .. " " .. dep
				end
				print("Current dependencies: " .. scratch_pad)
			end,
			exec_silent = true,
		},
		["ctrl-y"] = {
			fn = function(selected)
				local text = table.concat(selected, "\n") -- if it's a list of lines/items
				vim.fn.setreg("+", text)
				print("Dependency Copied:\n" .. text)
			end,
			exec_silent = true,
		},
		["ctrl-d"] = {
			fn = function(selected)
				if not selected or (type(selected) == "table" and #selected == 0) then
					print("No selection provided")
					return
				end

				-- Ensure selected is a table
				local raw_packages = type(selected) == "table" and selected or { selected }
				local packages = {}

				-- Filter out version info (e.g. from "pkg: ^1.2.3" -> "pkg")
				for _, line in ipairs(raw_packages) do
					-- Trim whitespace and remove everything after the colon
					local pkg = vim.trim(line):match("^[^:]+")
					if pkg and pkg ~= "" then
						table.insert(packages, pkg)
					end
				end

				if #packages == 0 then
					print("No valid packages to remove")
					return
				end

				-- Construct the pnpm command
				local cmd = { "pnpm", "remove", unpack(packages) }

				-- Create the Overseer task
				local task = require("overseer").new_task({
					name = table.concat(cmd, " "),
					cmd = cmd,
					on_exit = function(exit_code, output)
						if exit_code == 0 then
							print("✅ pnpm remove succeeded")
						else
							print("❌ pnpm remove failed with exit code: " .. exit_code)
							print("Output: " .. (output or "No output"))
						end
					end,
				})

				-- Start the task
				task:start()

				-- Optionally toggle Overseer UI
				vim.cmd("OverseerToggle")
			end,
			exec_silent = false,
		},
	}

	local current_dir = vim.fn.getcwd()
	local package_json_path = current_dir .. "/package.json"
	-- 💡 Add this BEFORE using `plugin_file` anywhere else

	local file = io.open(package_json_path, "r")
	if not file then
		print("There's no package.json: " .. package_json_path)
		return
	end

	local file_content = file:read("*all")
	file:close()

	local parsed = vim.fn.json_decode(file_content)
	if not parsed then
		print("Failed to parse package.json")
		return
	end

	local deps = parsed["dependencies"] or {}
	local dev_deps = parsed["devDependencies"] or {}

	local all_deps = {}
	for k, v in pairs(deps) do
		table.insert(all_deps, k .. ": " .. v)
	end
	for k, v in pairs(dev_deps) do
		table.insert(all_deps, k .. ": " .. v)
	end

	opts.fzf_opts = {
		["--preview"] = string.format("rg --context 5 --heading --line-number --color=always {} %s", package_json_path),
		["--preview-window"] = "right:60%:wrap",
	}
	fzf_lua.fzf_exec(all_deps, opts)
end

M.OptsDevices = function()
	local fzf_lua = require("fzf-lua")
	utils().last_selected(M.Devices)
	local opts = {
		prompt = "Select Devices> ",
		fzf_opts = {
			["--preview"] = "echo {}",
		},
		actions = { -- Correct key here
			["default"] = function(selected)
				-- If "Git Repos" is selected, call the fzf_dirs_git function to open another fzf
				if selected[1] == "Hard Disk" then
					M.HardDisk()
				-- If "Links" is selected, you can add code to handle that case here
				elseif selected[1] == "Removable Storage" then
					M.Devices()
					-- If "Links" is selected, you can add code to handle that case here
				end
			end,
		},
	}

	-- Define the choices for the fzf menu
	local choices = { "Hard Disk", "Removable Storage" }

	-- Open fzf for selecting between "Links" or "Git Repos"
	fzf_lua.fzf_exec(choices, opts)
end

M.Devices = function(opts)
	local fzf_lua = require("fzf-lua")
	utils().last_selected(M.Devices)
	opts = opts or {}
	opts.prompt = "G&Devices Directories> "
	opts.fn_transform = function(x)
		return fzf_lua.utils.ansi_codes.magenta(x) -- Change to cyan for a beautiful color
	end
	-- Function to get the last part of the directory (alias), removing trailing slashes

	opts.actions = {
		["default"] = function(selected)
			utils().open_dir(selected)
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
		["tab"] = function(selected)
			utils().open_dir_tmux(selected)
		end,
		["ctrl-s"] = {
			fn = function(selected)
				utils().horizontal(selected)
			end,
		},
		["alt-v"] = {
			fn = function(selected)
				utils().vertical(selected)
			end,
		},
		["ctrl-o"] = {
			fn = function()
				vim.cmd("Oil ")
			end,
		},
	}

	-- Initialize directories list (use a global variable to store them)
	-- local current_dir = vim.fn.getcwd()
	--
	-- -- Dynamically set the alias for the current directory to its name
	-- local current_dir_name = vim.fn.fnamemodify(current_dir, ":t") -- This gets the last part of the directory path (i.e., the name of the directory)
	-- local current_dir_name = current_dir_name .. " (" .. current_dir .. ")"

	S().directories_devices = S().directories_devices or {}

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
						table.insert(S().directories_devices, { path = drive .. ":", alias = alias })
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
						table.insert(S().directories_devices, { path = mount_point, alias = alias })
					end
				end
			end
		end
	end

	-- Define your predefined directories (same as before)
	local unique_directories = {}
	local seen = {}

	-- List subdirectories and process them
	for _, dir in ipairs(S().directories_devices) do
		-- Add the directory itself if not seen yet
		if not seen[dir.path] then
			seen[dir.path] = true
			table.insert(unique_directories, dir)
		end
	end

	-- Update the global directory list with the filtered, unique entries
	S().directories_devices = unique_directories

	-- Better! Transform the directories & speed it up into a format suitable for fzf
	local function fzf_lists(fzf_cb)
		coroutine.wrap(function()
			local co = coroutine.running()

			for _, dir in ipairs(S().directories_devices) do
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

M.HardDisk = function(opts)
	local fzf_lua = require("fzf-lua")
	utils().last_selected(M.HardDisk)
	opts = opts or {}
	opts.prompt = "HardDisk"
	opts.fn_transform = function(x)
		return fzf_lua.utils.ansi_codes.magenta(x) -- Change to cyan for a beautiful color
	end
	-- Function to get the last part of the directory (alias), removing trailing slashes

	opts.actions = {
		-- ["default"] = function(selected)
		-- 	utils().open_dir(selected)
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
					-- print("Changed directory to: " .. selected_path)
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
		["tab"] = function(selected)
			local selected_path = utils().selected_path(selected)

			local tmux_session_name

			-- Handle root directory case
			if selected_path == "/dev/sda1" then
				selected_path = "/"
				tmux_session_name = "root"
			else
				tmux_session_name = utils().get_last_name(selected_path) -- Use directory name as tmux session name
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
					-- Check if the tmux session exists by using tmux has-session command
					-- local tmux_session_exists =
					-- 	vim.fn.system("tmux has-session -t " .. tmux_session_name .. ">/dev/null 2>&1")

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
				--     "tmu new-session -ds "
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
				-- print("Changed directory to: " .. selected_path)
			end

			if vim.g.neovide then
				vim.cmd("cd " .. selected_path)
				-- print("Changed directory to: " .. selected_path)
			end
		end,
		["ctrl-s"] = {
			fn = function(selected)
				utils().horizontal(selected)
			end,
		},
		["alt-v"] = {
			fn = function(selected)
				utils().vertical(selected)
			end,
		},
		["ctrl-o"] = {
			fn = function()
				vim.cmd("Oil ")
			end,
		},
	}

	local disks = {}
	if utils().is_windows() then
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
		local user = utils().get_user_home()
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
		for _ in output:gmatch("[^\r\n]+") do
			-- local name, size, fstype, mountpoint = line:match("(%S+)%s+(%S+)%s+(%S*)%s*(.*)")
			local name, size, fstype

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

M.Api = function(opts)
	local fzf_lua = require("fzf-lua")
	utils().last_selected(M.Api)
	opts = opts or {}
	opts.prompt = "API> "

	opts.actions = {
        ["alt-m"] = {
			fn = function()
				M.OptsMenu()
			end,
			exec_silent = true,
		},
		["ctrl-y"] = {
			fn = function(selected)
				-- Change the print statement to use vim.inspect to safely print the table
				print("DEBUGPRINT[1]: fzf.lua:858: selected=" .. vim.inspect(selected))
				vim.fn.setreg("+", selected)
				print("Path Copied: " .. vim.inspect(selected)) -- Use vim.inspect to print the table as a string
			end,
			exec_silent = true,
		},
		["default"] = {
			fn = function(selected)
				vim.fn.setreg("+", selected)
				print("Path Copied: " .. vim.inspect(selected)) -- Use vim.inspect to print the table as a string
			end,
			exec_silent = true,
		},
	}

	-- Predefined array of popular links (with the base domain)
	local popular_links = {
		"https://jsonplaceholder.typicode.com/users",
		"https://jsonplaceholder.typicode.com/comments",
		"https://api.thedogapi.com/v1/images/search",
		"https://api.thecatapi.com/v1/images/search",
		"https://api.coingecko.com/api/v3/simple/price?ids=bitcoin&vs_currencies=usd",
		"https://restcountries.com/v3.1/all",
		"https://v2.jokeapi.dev/joke/Programming",
		"https://opentdb.com/api.php?amount=10&type=multiple", -- Changed to the actual URL for Neovim
		"https://gateway.marvel.com/v1/public/characters?apikey={API_KEY}", -- Changed to the actual URL for Neovim
		"https://pokeapi.co/api/v2/pokemon/{id_or_name}", -- Fixed typo from "reedit.com"
		"https://newsapi.org/v2/top-headlines?country=us&apiKey={API_KEY}", -- Changed to the actual URL for Neovim
		"https://restcountries.com/v3.1/name/{country_name}",
		"https://api.openweathermap.org/data/2.5/weather?q={city name}&appid={API_KEY}",
		"https://api.ipgeolocation.io/ipgeo?apiKey={API_KEY}&ip={ip_address}",
	}

	-- Execute fzf with the predefined popular links
	fzf_lua.fzf_exec(popular_links, opts)
end
M.Links = function(opts)
	local fzf_lua = require("fzf-lua")
	utils().last_selected(M.Links)
	opts = opts or {}
	opts.prompt = "Links> "

	opts.actions = {
		["alt-m"] = {
			fn = function()
				M.OptsMenu()
			end,
			exec_silent = true,
		},
		["default"] = {
			fn = function(selected)
				local selected_url = utils().selected_path(selected)
				-- Ensure the link is properly formatted with 'https://'
				local repo_url = selected_url
				--
				-- -- Check if the operating system is Windows or non-Windows
				if utils().is_windows() then
					-- For Windows, use 'start' or 'explorer' to open the URL
					os.execute("start " .. repo_url) -- You can also use "explorer" if needed
				else
					-- For non-Windows systems (Linux/macOS), use 'xdg-open' to open the URL
					os.execute("xdg-open " .. repo_url)
				end
			end,
			exec_silent = true,
		},
	}

	-- Predefined array of popular links (with the base domain)
	local links = {
		{
			alias = "https://facebook.com",
			path = "Social media platform for connecting with friends and communities.",
		},
		{
			alias = "https://ui.shadcn.com",
			path = "UI components and design system for building modern web apps.",
		},
		{
			alias = "https://chatgpt.com",
			path = "Conversational AI by OpenAI for assistance, coding, and more.",
		},
		{ alias = "https://youtube.com", path = "Video sharing and streaming platform." },
		{
			alias = "https://github.com",
			path = "Code hosting platform for version control and collaboration.",
		},
		{ alias = "https://dotfyle.com", path = "Neovim plugin manager and explorer." },
		{ alias = "https://outlook.com", path = "Web-based email service by Microsoft." },
		{ alias = "https://comick.io", path = "Online comic and manga reading platform." },
		{ alias = "https://mgeko.cc", path = "Another online manga/comic platform." },
		{
			alias = "https://asuracomic.net",
			path = "Site for reading translated manga and webtoons.",
		},
		{ alias = "https://gmail.com", path = "Google's email service." },
		{ alias = "https://google.com", path = "Search engine and tech services provider." },
		{
			alias = "https://reddit.com",
			path = "Community-based discussion and content sharing site.",
		},
		{ alias = "https://neovim.io", path = "Official site for the Neovim text editor." },
		{
			alias = "https://fonts.google.com",
			path = "Google Fonts library for open-source typography.",
		},
		{
			alias = "https://search.nixos.org",
			path = "Search tool for NixOS packages and options.",
		},
		{
			alias = "https://storyset.com/",
			path = "Free animated illustrations and vector art for web and design projects.",
		},
		{
			alias = "https://msn.com/en-ph/weather",
			path = "Local weather forecasts and updates for the Philippines from MSN.",
		},
		{
			alias = "https://onehack.us/c/tutorials-methods/7",
			path = "Forum section with tutorials and methods for tech enthusiasts and hackers.",
		},
		{
			alias = "https://www.patterns.dev/posts/tree-shaking",
			path = "In-depth guide on JavaScript tree shaking for optimizing web bundlers.",
		},
		{
			alias = "https://github.com/leonardomso/33-js-concepts",
			path = "JavaScript best practices: factories and classes explained (Concept #14).",
		},
		{
			alias = "https://getintopc.com/",
			path = "Website offering free downloads of software and PC applications.",
		},
		{
			alias = "https://www.freesoftwarefiles.com/",
			path = "Directory of free software downloads for Windows and Mac.",
		},
		{
			alias = "https://downloadlyir.com",
			path = "Resource site for downloading premium software and tools for free.",
		},
		{
			alias = "localhost:5173/",
			path = "Vite Local Development",
		},
		{
			alias = "localhost:3000",
			path = "React Local Development",
		},
		{
			alias = "localhost:4173",
			path = "Vite Prod Development",
		},
		{
			alias = "localhost:8000",
			path = "Cloudflare Local Development",
		},
		{
			alias = "https://github.com/NvChad/base46/blob/v3.0/lua/base46/themes/ashes.lua",
			path = "base46",
		},
	}

	ui().calculate_padding(links)
	-- Prepare entries for FZF with proper alignment
	local fzf_entries = {}
	for _, link in ipairs(links) do
		local padded_name = string.format("%-" .. ui().max_alias_len .. "s", link.alias)
		local padded_desc = string.format("%-" .. ui().max_path_len .. "s", link.path)
		local url = string.format("%-" .. #link.alias + 2 .. "s", "⟨" .. link.alias .. "⟩") -- +2 for the parentheses

		table.insert(fzf_entries, string.format("%s │ %s │ %s", padded_name, padded_desc, url))
	end
	-- Execute fzf with the predefined popular links
	fzf_lua.fzf_exec(fzf_entries, opts)
end

M.CmdLine = function(opts)
	local fzf_lua = require("fzf-lua")
	opts = opts or {}
	opts.prompt = "Regex Rename> "

	-- Regex snippets with descriptions
	local scripts = {
		{ cmd = "'<,'>s/\\v(\\w+)\\s*=\\s*(\\w+)/\\2 = \\1/g", desc = "Swap LHS and RHS of assignments" },
		{ cmd = "'<,'>s/\\v(.*):\\s*(.*)/\\2: \\1/g", desc = "Swap colon-separated key-value pairs" },
		{ cmd = "'<,'>s/\\v(\\d{4})-(\\d{2})-(\\d{2})/\\3\\/\\2\\/\\1/g", desc = "YYYY-MM-DD to DD/MM/YYYY" },
		{ cmd = "set filetype?", desc = "fIletype" },
		{ cmd = "set filetype=sh", desc = "sh" },
	}

	-- Format each item for display in fzf
	local display_items = vim.tbl_map(function(item)
		return string.format("%s | %s", item.cmd, item.desc)
	end, scripts)

	-- Define action on selection
	opts.actions = {
		["alt-m"] = {
			fn = function()
				M.OptsMenu()
			end,
			exec_silent = true,
		},
		["default"] = function(selected)
			local cmd = selected[1]:match("^(.-)%s+|")
			if cmd then
				-- Open : command-line and paste the command
				vim.api.nvim_feedkeys(":" .. cmd, "n", false)
			end
		end,
		["tab"] = function(selected)
			local cmd = selected[1]:match("^(.-)%s+|")
			if cmd then
				vim.cmd("vnew") -- open vertical split
				vim.api.nvim_buf_set_lines(0, 0, -1, false, {
					"-- Edit and run this regex in visual mode",
					cmd,
				})
				vim.bo.buftype = "nofile"
				vim.bo.bufhidden = "wipe"
				vim.bo.swapfile = false
				vim.bo.filetype = "vim"
			end
		end,
	}

	fzf_lua.fzf_exec(display_items, opts)
end
M.Commands = function(opts)
	local fzf_lua = require("fzf-lua")
	opts = opts or {}
	opts.prompt = opts.prompt or "Select Command> "
	local home = os.getenv("HOME")
	local file = home .. "/.shell/commands.txt"

	-- Read and parse commands file into a table of { display = ..., cmd = ... }
	local lines = {}
	for line in io.lines(file) do
		-- Line format: ⟨command⟩│description
		-- Extract command inside ⟨...⟩ and description after │
		local cmd, desc = line:match("⟨(.-)⟩│(.*)")
		if cmd then
			cmd = cmd:gsub("^%s*(.-)%s*$", "%1") -- trim spaces
			desc = desc and desc:gsub("^%s*(.-)%s*$", "%1") or ""
			-- Format display line similar to your Bash: icon + padded command + desc
			local display = string.format(" %-60s  %s", "⟨" .. cmd .. "⟩", desc)
			table.insert(lines, { display = display, cmd = cmd })
		end
	end

	opts.actions = {
		["alt-m"] = {
			fn = function()
				M.OptsMenu()
			end,
			exec_silent = true,
		},
		["default"] = function(selected)
			local sel = selected[1]
			if sel:match("⟨(.-)⟩") then
				-- If path is inside parentheses, extract it
				sel = sel:match("⟨(.-)⟩")
			end
			vim.fn.setreg("+", sel)
			print("Command Copied: " .. sel)

            -- Paste at cursor

			-- local row, col = unpack(vim.api.nvim_win_get_cursor(0))
			-- vim.api.nvim_put({ sel }, "c", true, true) -- after cursor

			-- Highlight the newly inserted text
			-- local ns_id = vim.api.nvim_create_namespace("select_cmd_highlight")
			-- local line_len = #cmd
			-- vim.api.nvim_buf_add_highlight(0, ns_id, "Visual", row - 1, col, col + line_len)
			--
			-- -- Remove the highlight after a short time (e.g., 300ms)
			-- vim.defer_fn(function()
			-- 	vim.api.nvim_buf_clear_namespace(0, ns_id, 0, -1)
			-- end, 300)
		end,
		["alt-s"] = function(selected)
			local sel = selected[1]
			if sel:match("⟨(.-)⟩") then
				-- If path is inside parentheses, extract it
				sel = sel:match("⟨(.-)⟩")
			end
			local task = require("overseer").new_task({
				name = sel,
				cmd = sel,
				on_exit = function(exit_code, output)
					-- Custom handling based on exit code and output
					if exit_code == 0 then
						print("Task completed successfully!")
					else
						print("Task failed with exit code " .. exit_code)
						print("Error output: " .. (output or "No output"))
					end
				end,
			})

			-- Start the task
			task:start()

			-- Toggle Overseer UI (optional)
			vim.cmd("OverseerToggle")
			-- Find cmd by display
		end,
		["ctrl-o"] = {
			fn = function(selected)
				local sel = selected[1]
				if sel:match("⟨(.-)⟩") then
					-- If path is inside parentheses, extract it
					sel = sel:match("⟨(.-)⟩")
				end

				-- Execute the link directly based on the OS
				if package.config:sub(1, 1) == "\\" then
					-- For Windows, use 'start' or 'explorer' to open the URL (paste the link into the browser)
					os.execute("start " .. sel)
				else
					-- Construct the terminal command to run
					-- Construct the terminal command to run with alacritty
					local terminal_command = 'alacritty -e bash -c "' .. sel .. '; exec bash"'

					-- Open the terminal in Neovim and run the command
					vim.cmd("term " .. terminal_command)
				end
			end,
		},
		["ctrl-y"] = {
			fn = function(selected)
				local sel = selected[1]
				if sel:match("⟨(.-)⟩") then
					-- If path is inside parentheses, extract it
					sel = sel:match("⟨(.-)⟩")
				end
				-- local text = table.concat(sel, "\n")
				vim.fn.setreg("+", sel)
				print("Command Copied: " .. sel)
			end,
		},
	}
	local entries = {}
	for _, entry in ipairs(lines) do
		table.insert(entries, entry.display)
	end

	-- Use fzf-lua to pick from entries
	fzf_lua.fzf_exec(entries, opts)
end
M.NvimPlugins = function(opts)
	local fzf_lua = require("fzf-lua")
	utils().last_selected(M.NvimPlugins)
	opts = opts or {}
	opts.prompt = "Plugin Links> "
	local plugin_file

	if utils().is_windows() then
		-- For Windows, construct path using home
		plugin_file = utils().home .. "\\AppData\\Local\\nvim\\lua\\plugins\\init.lua"
	else
		-- For Unix-like systems, use this path
		plugin_file = utils().home .. "/.config/nvim/lua/plugins/init.lua"
	end

	opts.fzf_opts = {
		["--preview"] = string.format("rg --context 5 --heading --line-number --color=always {} %s", plugin_file),
		["--preview-window"] = "right:60%:wrap",
	}
	opts.actions = {
		["default"] = {
			fn = function(selected)
				-- Get the selected dependency name from the FZF result
				local dep = selected[1]

				-- Build the full path to the package.json file in the current working directory
				-- local package_json = vim.fn.getcwd() .. "/package.json"

				-- Prepare the ripgrep command to search for the dependency in package.json
				-- This looks for lines like: "react": "^18.2.0"
				local quote = [[""]]
				local rg_cmd
				if package.config:sub(1, 1) == "\\" then
					rg_cmd = "rg --line-number " .. quote .. dep .. quote .. " " .. quote .. plugin_file .. quote
				else
					rg_cmd = "rg --line-number '\"" .. dep .. '"\' "' .. plugin_file .. '"'
				end

				-- Execute the ripgrep command and read the output
				local handle = io.popen(rg_cmd)
				local result = handle and handle:read("*a") or ""
				if handle then
					handle:close()
				end

				-- Extract the first matching line number from the output (e.g., "32: \"react\":...")
				local line_number = result:match("^(%d+):")
				line_number = tonumber(line_number)

				if line_number then
					-- If we found a matching line, open package.json in the buffer
					vim.cmd("edit " .. plugin_file)

					-- Move the cursor to the matched line number at column 1
					vim.fn.cursor({ line_number, 1 })
				else
					-- If no match was found, show an error message
					print("Plugin dependency not found: ", dep)
				end
			end,
		},
        ["alt-m"] = {
			fn = function()
				M.OptsMenu()
			end,
			exec_silent = true,
		},
		["ctrl-y"] = {
			fn = function(selected)
				if type(selected) == "table" then
					selected = table.concat(selected, " ")
				end
				vim.fn.setreg("+", selected)
				print("Path Copied" .. selected)
			end,
			exec_silent = true,
		},
		["tab"] = {
			fn = function(selected)
				if type(selected) == "table" then
					selected = table.concat(selected, " ")
				end
				-- Ensure the link is properly formatted with 'https://'
				local repo_url = "https://github.com/" .. selected

				-- Check if the operating system is Windows or non-Windows
				if package.config:sub(1, 1) == "\\" then
					-- For Windows, use 'start' or 'explorer' to open the URL
					os.execute("start " .. repo_url) -- You can also use "explorer" if needed
				else
					-- For non-Windows systems (Linux/macOS), use 'xdg-open' to open the URL
					os.execute("xdg-open " .. repo_url)
				end
			end,
			exec_silent = true,
		},
	}

	local file = io.open(plugin_file, "r")
	if not file then
		print("Failed to open file: " .. plugin_file)
		return
	end

	local file_content = file:read("*all")
	file:close()

	local links = {}

	-- Extract only the plugin names with '/' in them, ignoring other fields like 'build', 'event', etc.
	for link in string.gmatch(file_content, '"([^"\'%s]+/[^"\'%s]+)"') do
		table.insert(links, link)
	end

	if #links == 0 then
		return
	end

	fzf_lua.fzf_exec(links, opts)
end

M.GitRepo = function(opts)
	local fzf_lua = require("fzf-lua")
	utils().last_selected(M.GitRepo)
	opts = opts or {}
	opts.prompt = "Git Repos> "
	opts.fn_transform = function(repo)
		-- Highlight repo names in yellow for example
		return fzf_lua.utils.ansi_codes.yellow(repo)
	end

	-- Helper function to get GitHub username
	local function get_github_username()
		local username_command = "gh api user -q .login"
		local handle = io.popen(username_command)
		local username = handle:read("*a"):gsub("%s+", "") -- Remove any extra whitespace
		handle:close()
		return username
	end

	-- Helper function to check if ssh-agent is running
	local function is_ssh_agent_running()
		local check_ssh_agent_command = "ps aux | grep sshd"
		local handle = io.popen(check_ssh_agent_command)
		local ssh_agent_process = handle:read("*a"):gsub("%s+", "") -- Read the process list output
		handle:close()
		return #ssh_agent_process > 0
	end

	-- Remove the leading and trailing quotes if they exist
	local function remove_quotes(str)
		return str:match("^[\"'](.-)[\"']$") or str
	end

	-- List of custom repositories (add as many as you like here)
	local custom_repos = {
		"stevearc/oil.nvim",
	}
	-- Helper function to construct the git clone URL
	local function get_clone_url(username, repo)
		-- Check if we are on Windows
		if package.config:sub(1, 1) == "\\" then
			-- Windows uses HTTPS
			if repo:match("/") then
				return "https://github.com/" .. remove_quotes(repo)
			else
				return "https://github.com/" .. username .. "/" .. repo .. ".git"
			end
		else
			-- Unix-based OS: use SSH if agent is running, else use HTTPS
			local use_ssh = is_ssh_agent_running()
			if use_ssh then
				-- List of custom repositories (add as many as you like here)
				if repo:match("/") then
					-- If the repository belongs to the user, use the username for the clone URL
					return "git@github.com:" .. repo .. ".git"
				else
					-- Otherwise, it's a public repo (no username specified)
					return "git@github.com:" .. username .. "/" .. repo .. ".git"
				end
			else
				return "https://github.com/" .. username .. "/" .. repo .. ".git"
			end
		end
	end

	opts.actions = {
        ["alt-m"] = {
			fn = function()
				M.OptsMenu()
			end,
			exec_silent = true,
		},
		["default"] = {
			fn = function(selected)
				-- Get the GitHub username
				local username = get_github_username()

				-- Get the selected repository (in the form 'owner/repo')
				local repo = selected[1]

				-- If no repo selected, use the custom repositories
				if not repo or repo == "" then
					repo = custom_repos[1] -- Default to the first custom repo
				end

				-- Get the correct git clone URL
				local clone_url = get_clone_url(username, repo)

				-- Run the git clone command
				local result = "git clone " .. clone_url
				-- Run the command using vim.fn.system to capture the output
				-- local result = vim.fn.system(cmd)
				local task = require("overseer").new_task({
					name = result,
					cmd = result,
				})
				task:start()
				vim.cmd("OverseerToggle")
			end,
		},
		["tab"] = {
			fn = function(selected)
				-- Get the GitHub username
				local username = get_github_username()

				-- Get the selected repository (in the form 'owner/repo')
				local repo = selected[1]

				-- If no repo selected, use the custom repositories
				if not repo or repo == "" then
					repo = custom_repos[1] -- Default to the first custom repo
				end

				-- Get the correct git clone URL
				local clone_url = get_clone_url(username, repo)

				-- Run the git clone command
				local cmd = "git clone " .. clone_url
				-- Run the command using vim.fn.system to capture the output
				local result = vim.fn.system(cmd)

				-- Check if the command was successful
				if vim.v.shell_error ~= 0 then
					print("Failed to clone repository. Error: " .. result)
				else
					print("Cloning repository was successful.")
				end
			end,
			exec_silent = true,
		},
		["ctrl-y"] = {
			fn = function(selected)
				local text = table.concat(selected, "\n")
				vim.fn.setreg("+", text)
				print("Command Copied: " .. text)
			end,
		},
	}
	-- Fetch GitHub repos using 'gh' CLI command
	-- Modify `gh repo list` with the appropriate flags (e.g., private repos, number of repos)

	local command
	if package.config:sub(1, 1) == "\\" then
		command = [[ gh repo list --limit 100 --json name,owner | jq -r ".[] | .name" ]]
	else
		command =
			[[ gh repo list --limit 100 --json name,owner | grep -oP '\"name\":\s*\"[^\"]+\"' | awk -F '\"' '{print $4}' ]]
	end

	-- Combine the list of GitHub repos with the custom repositories (add them to the list)
	local combined_command = command
	for _, repo in ipairs(custom_repos) do
		combined_command = combined_command .. " && echo " .. repo
	end

	-- Execute the command and feed the results into fzf
	fzf_lua.fzf_exec(combined_command, opts)
end

-- M.fzf_dirs = function(opts)
-- 	local fzf_lua = require("fzf-lua")
-- 	opts = opts or {}
-- 	opts.prompt = "Directories> "
-- 	opts.fn_transform = function(x)
-- 		return fzf_lua.utils.ansi_codes.magenta(x)
-- 	end
-- 	opts.actions = {
-- 		["default"] = function(selected)
-- 			vim.cmd("cd " .. selected[1])
-- 		end,
-- 	}
-- 	print("fzf dirs error")
-- 	fzf_lua.fzf_exec("fd --type d", opts)
-- end

return M
