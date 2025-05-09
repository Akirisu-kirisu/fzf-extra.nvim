local fzf_lua = require("fzf-lua")
local utils = require("extras.utils")
local ui = require("extras.ui")
local extra_actions = require("extras.actions")
local history_utils = require("extras.history-utils.history-utils")

require("extras.functions.select_dir_mfe.open_local")

-- //main-menu-mfs
require("extras.functions.main_menu_mfs.select_git_repo")
require("extras.functions.main_menu_mfs.select_config_lua_plugins")
require("extras.functions.main_menu_mfs.select_commands")
require("extras.functions.main_menu_mfs.select_links")
require("extras.functions.main_menu_mfs.select_api")
require("extras.functions.main_menu_mfs.select_search_current_dir_packages")
require("extras.functions.main_menu_devices_mfd.select_removable_devices")
require("extras.functions.main_menu_devices_mfd.select_hardDisk_devices")

require("extras.directories")

local M = {}
_G.select_directory_global_mfe = function(opts)
	opts = opts or {}
	opts.prompt = "Global Directories> "
	opts.fn_transform = function(x)
		return fzf_lua.utils.ansi_codes.magenta(x) -- Change to cyan for a beautiful color
	end

	opts.actions = {
		["ctrl-y"] = {
			fn = function(selected)
				extra_actions.captures_parentheses_copy(selected)
			end,
			exec_silent = true,
		},
		["default"] = {
			fn = function(selected)
				extra_actions.open_dir(selected)
			end,
			exec_silent = true,
		},
		-- Custom key binding for the 'Tab' key (using 'ctrl-v' + Tab for input mapping)
		["tab"] = function(selected)
			extra_actions.open_dir_tmux(selected)
		end,
	}

	utils.get_current_dir(_G.directories)

	-- utils.subdirs(_G.directories)

	local function fzf_lists(fzf_cb)
		coroutine.wrap(function()
			local co = coroutine.running()
			ui.calculate_padding(_G.directories)
			for _, dir in ipairs(_G.directories) do
				-- local timestamp = utils.get_timestamp(dir.path) cost performance

				local output = ui.format_directory_output(dir, ui.max_path_len)

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

_G.select_main_menu_mfs = function()
	local opts = {
		prompt = "Select Option> ",
		fzf_opts = {
			["--preview"] = "echo {}",
		},
		actions = { -- Correct key here
			["default"] = function(selected)
				-- If "Git Repos" is selected, call the fzf_dirs_git function to open another fzf
				if selected[1] == "Git Repos" then
					_G.select_git_repo()
				elseif selected[1] == "Plugins" then
					-- If "Links" is selected, you can add code to handle that case here
					_G.select_configuration_lua_plugins()
				elseif selected[1] == "Commands" then
					--   -- If "Links" is selected, you can add code to handle that case here
					_G.select_commands()
				elseif selected[1] == "Links" then
					--   -- If "Links" is selected, you can add code to handle that case here
					_G.select_links()
				elseif selected[1] == "API" then
					--   -- If "Links" is selected, you can add code to handle that case here
					_G.select_api()
				elseif selected[1] == "Packages" then
					-- If "Links" is selected, you can add code to handle that case here
					_G.select_search_current_dir_packages()
				end
			end,
		},
	}
	-- Define the choices for the fzf menu
	local choices = { "Plugins", "Git Repos", "Links", "Commands", "API", "Packages" }

	-- Open fzf for selecting between "Links" or "Git Repos"
	fzf_lua.fzf_exec(choices, opts)
end

_G.main_menu_devices_mfd = function()
	local opts = {
		prompt = "Select Option> ",
		fzf_opts = {
			["--preview"] = "echo {}",
		},
		actions = { -- Correct key here
			["default"] = function(selected)
				-- If "Git Repos" is selected, call the fzf_dirs_git function to open another fzf
				if selected[1] == "Hard Disk" then
					_G.select_hardDisk_devices()
				-- If "Links" is selected, you can add code to handle that case here
				elseif selected[1] == "Removable Storage" then
					_G.select_removable_devices()
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

_G.select_filePath = function(opts)
	opts = opts or {}
	opts.prompt = "Current Dir or File> "

	opts.actions = {
		["default"] = {
			fn = function(selected)
				if type(selected) == "table" then
					selected = table.concat(selected, " ")
				end

				-- Get current directory and file name
				local current_dir = vim.fn.getcwd()
				local current_file = vim.fn.expand("%:t") -- Get current file name

				-- Combine the directory and the file name
				local full_path = current_dir .. "/" .. current_file
				local dir_path = current_dir -- Just the directory

				-- Decide whether to use full path or just directory path
				local path_to_copy
				if selected == "Directory" then
					path_to_copy = dir_path
				else
					path_to_copy = full_path
				end

				-- Print the path to the command line
				vim.fn.setreg("+", path_to_copy)
				print("Path: " .. path_to_copy)

				-- Optionally, copy the path to the system clipboard
				if vim.fn.has("unix") == 1 then
					os.execute("echo -n '" .. path_to_copy .. "' | xclip -selection clipboard")
				elseif vim.fn.has("win32") == 1 or vim.fn.has("win64") == 1 then
					os.execute("echo " .. path_to_copy .. " | clip")
				end
			end,
			exec_silent = true,
		},
	}

	-- Predefined options: "Directory" or "Full Path (Dir + File)"
	local options = { "Directory", "Full Path (Dir + File)" }

	-- Execute fzf to let the user choose either the directory or full path
	fzf_lua.fzf_exec(options, opts)
end

_G.select_local_directories = function(opts)
	opts = opts or {}
	opts.prompt = "Directories> "
	opts.fn_transform = function(x)
		return fzf_lua.utils.ansi_codes.green(x)
	end

	opts.actions = {
		["default"] = function(selected)
			local selected_path = selected[1]:gsub(" ", "") -- Remove the " " prefix
			-- Check if the directory exists before attempting to change into it
			if selected_path == nil or selected_path == "" then
				print("Error: No valid path selected.")
				return
			end
			if vim.fn.isdirectory(selected_path) == 1 then
				vim.cmd("Oil " .. selected_path)
				print("Changed directory to: " .. selected_path)
			else
				print("Directory does not exist: " .. selected_path)
			end
		end,
		["tab"] = function(selected)
			extra_actions.open_dir_tmux(selected)
		end,
		["alt-m"] = {
			fn = function(selected)
				_G.select_directory_global_mfe()
			end,
			exec_silent = true,
		},
	}

	local fzf_list = {}
	local fd_command = "fd --type d --exclude node_modules"

	-- Execute the 'fd' command and capture the output
	local output = vim.fn.systemlist(fd_command)

	-- Iterate over the directories found by 'fd' and prepare them for fzf
	for _, subdir in ipairs(output) do
		if vim.fn.isdirectory(subdir) == 1 then
			-- table.insert(fzf_list, subdir)
			table.insert(fzf_list, "" .. " " .. subdir)
		end
	end

	-- Proceed with launching fzf
	fzf_lua.fzf_exec(fzf_list, opts)
end

_G.select_hidden_directories = function(opts)
  opts = opts or {}
  opts.prompt = "Hidden Directories> "
  opts.fn_transform = function(x)
    return fzf_lua.utils.ansi_codes.magenta(x)
  end
  opts.actions = {
    ["default"] = function(selected)
      vim.cmd("cd " .. selected[1])
    end,

    ["tab"] = function(selected)
      extra_actions.open_dir_tmux(selected)
    end,
  }
  -- Modify the fd command to correctly search hidden directories and exclude .git
  -- Also, ensure to include directories that are hidden (starting with a dot)
  fzf_lua.fzf_exec("fd --type d --hidden --exclude node_modules --absolute-path --max-depth 1 .", opts)
end


_G.select_history_directories = function(opts)
  opts = opts or {}
  opts.prompt = "History> "

  -- Load stored history
  local stored = history_utils.read_history()

  -- Merge with session's history
  for dir, _ in pairs(_G.directories_history) do
    stored[dir] = true
  end

  -- Save merged version
  history_utils.write_history(stored)

  -- Convert to list with uniqueness
  local seen = {}
  local dir_list = {}

  for dir, _ in pairs(stored) do
    if not seen[dir] then
      seen[dir] = true
      table.insert(dir_list, dir)
    end
  end

  opts.actions = {
    ["ctrl-d"] = {
      fn = function(selected)
        if type(selected) == "table" then
          selected = selected[1]
        end

        -- Remove from current session history
        _G.directories_history[selected] = nil

        -- Also remove from file history
        local stored_history = history_utils.read_history()
        stored_history[selected] = nil
        history_utils.write_history(stored_history)

        print("Removed from history: " .. selected)
      end,
    },
    ["default"] = {
      fn = function(selected)
        if type(selected) == "table" then
          selected = selected[1]
        end
        vim.cmd("cd " .. selected)
        print("Jumped to " .. selected)
      end,
    },
    ["tab"] = function(selected)
		extra_actions.open_dir_tmux(selected)
      end,
    ["ctrl-y"] = {
      fn = function(selected)
        if type(selected) == "table" then
          selected = selected[1]
        end
        -- Copy to system clipboard
        vim.fn.setreg("+", selected)
        print("Copied to clipboard: " .. selected)
      end,
      exec_silent = true,
    },
  }

  require("fzf-lua").fzf_exec(dir_list, opts)
end

return M
