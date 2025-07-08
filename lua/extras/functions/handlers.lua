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
	utils.last_selected(select_directory_global_mfe)
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
			-- exec_silent = true,
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
	utils.last_selected(select_main_menu_mfs)

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
				elseif selected[1] == "Terminal Commands" then
					--   -- If "Links" is selected, you can add code to handle that case here
					_G.select_terminal_commands()
				elseif selected[1] == "Neovim Cmdline" then
					--   -- If "Links" is selected, you can add code to handle that case here
					_G.select_nvim_commands()
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
	local choices = { "Plugins", "Git Repos", "Links", "Terminal Commands", "Neovim Cmdline", "API", "Packages" }

	-- Open fzf for selecting between "Links" or "Git Repos"
	fzf_lua.fzf_exec(choices, opts)
end

_G.main_menu_devices_mfd = function()
	utils.last_selected(main_menu_devices_mfd)
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
	-- utils.last_selected(select_filePath)
	opts = opts or {}
	opts.prompt = "Current Dir or File> "

	opts.actions = {
		["default"] = {
			fn = function(selected)
				if type(selected) == "table" then
					selected = table.concat(selected, " ")
				end

				-- Get full path and directory of the current buffer
				local full_path = vim.fn.expand("%:p")
				local current_dir = vim.fn.expand("%:p:h")

				-- Decide whether to use full path or just directory path
				local path_to_copy
				if selected == "Directory" then
					path_to_copy = current_dir
				else
					path_to_copy = full_path
				end

				vim.fn.setreg("+", path_to_copy)
				print("Path: " .. path_to_copy)
                vim.api.nvim_paste(path_to_copy, true, -1)

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

_G.select_hidden_directories = function(opts)
	utils.last_selected(select_hidden_directories)
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
            _G.select_hidden_files()
		end,

        ["alt-m"] = {
            fn = function(selected)
                _G.select_directory_global_mfe()
            end,
        },

		["tab"] = function(selected)
			extra_actions.open_dir_tmux(selected)
		end,
	}
	-- Modify the fd command to correctly search hidden directories and exclude .git
	-- Also, ensure to include directories that are hidden (starting with a dot)
	-- fzf_lua.fzf_exec("fd --type d --hidden --exclude node_modules '.*' ! -name '.' --absolute-path --max-depth 1 .", opts)
    fzf_lua.fzf_exec("find . -maxdepth 1 -type d -name '.*' ! -name '.' -exec realpath {} \\;", opts)
end

_G.select_hidden_files = function(opts)
	utils.last_selected(select_hidden_files)
	opts = opts or {}
	opts.prompt = "Hidden Files> "
	opts.fn_transform = function(x)
		return require("fzf-lua.utils").ansi_codes.magenta(x)
	end
	opts.actions = {
		["default"] = function(selected)
			vim.cmd("edit " .. vim.fn.fnameescape(selected[1]))
		end,

		["alt-s"] = function(selected)
            _G.select_hidden_directories()
		end,

        ["alt-m"] = {
            fn = function(selected)
                _G.select_directory_global_mfe()
            end,
        },

		["tab"] = function(selected)
			extra_actions.open_file_tmux(selected)
		end,
	}

	-- Use `find` to get hidden files (exclude `.` and `..`, use realpath for clarity)
	local find_cmd = "find . -maxdepth 1 -type f -name '.*' -exec realpath {} \\;"
	require("fzf-lua").fzf_exec(find_cmd, opts)
end

_G.select_history_directories = function(opts)
	utils.last_selected(select_history_directories)
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
				vim.cmd("Oil " .. selected)
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

_G.select_open_files = function(opts)
	utils.last_selected(select_open_files)
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

		["alt-m"] = function(selected)
			_G.select_local_directories_max_1()
		end,
	}

	fzf_lua.fzf_exec("fd --type f", opts) -- fd command for files
end

_G.select_git_commits = function(opts)
	utils.last_selected(select_git_commits)
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
function M.previousDirectories()

	-- Format the list with aliases
	local formatted = {}
	for _, entry in ipairs(_G.directories_temp_back or {}) do
		table.insert(formatted, string.format("[%d] %s", entry.alias, entry.path))
	end

	-- Picker options
	local opts = {
		prompt = "Global Directories> ",
		fn_transform = function(x)
			return utils.ansi_codes.cyan(x) -- cyan = more readable
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
	print("DEBUGPRINT[94]: _G.directories_temp_back = " .. vim.inspect(_G.directories_temp_back))
end


vim.keymap.set({ "n" }, "mxw", function()
	M.previousDirectories()
end, { desc = "Run last selected directory picker" })

return M
