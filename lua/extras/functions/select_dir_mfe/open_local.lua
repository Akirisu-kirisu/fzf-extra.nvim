local fzf_lua = require("fzf-lua")
local ui = require("extras.ui")
local utils = require("extras.utils")
local extra_actions = require("extras.actions")

_G.select_local_directories = function(opts)
	utils.last_selected(select_local_directories)
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
				extra_actions.open_oil(selected)
			end,
		},
		["alt-s"] = function(selected)
			vim.cmd('Oil ')
		end,
		-- Custom key binding for the 'Tab' key (using 'ctrl-v' + Tab for input mapping)
		["tab"] = function(selected, opts)
			extra_actions.open_dir_tmux(selected)
		end,
		["alt-m"] = {
			fn = function(selected)
				_G.select_directory_global_mfe()
			end,
		},
		["alt-d"] = {
			fn = function(selected)
				_G.select_local_directories_max_1()
			end,
			exec_silent = true,
		},
		["alt-e"] = function(selected)
			-- require'fzf-lua'.files()
			_G.select_open_files()
		end,
	}

	local fzf_list = {}
	local fd_command = "fd --type d --exclude node_modules --max-depth 3 ."

	-- Execute the 'fd' command and capture the output
	local output = vim.fn.systemlist(fd_command)

	-- Iterate over the directories found by 'fd' and prepare them for fzf
	for _, subdir in ipairs(output) do
		if vim.fn.isdirectory(subdir) == 1 then
			local lastname = utils.get_last_name(subdir)
			local path = subdir

			table.insert(fzf_list, { alias = lastname, path = path })
		end
	end

	ui.calculate_padding(fzf_list)
	local formatted_list = {}
	for _, subdir in ipairs(fzf_list) do
		local formatted_ui = ui.format_directory_output(subdir, ui.max_path_len)
		table.insert(formatted_list, formatted_ui)
	end

	fzf_lua.fzf_exec(formatted_list, opts)
end

_G.select_local_directories_max_1 = function(opts)
	utils.last_selected(select_local_directories_max_1)
	opts = opts or {}
	opts.prompt = "Directories> "
	opts.fn_transform = function(x)
		return fzf_lua.utils.ansi_codes.green(x)
	end

	opts.actions = {
		["default"] = {
			fn = function(selected)
				extra_actions.open_dir(selected)
			end,
			exec_silent = true,
		},
		["alt-s"] = function(selected)
			vim.cmd("Oil ")
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
		["alt-d"] = {
			fn = function(selected)
				_G.select_local_directories()
			end,
			exec_silent = true,
		},
		["alt-e"] = {
			fn = function(selected)
				_G.select_open_files()
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
			local lastname = utils.get_last_name(subdir)
			local path = subdir

			table.insert(fzf_list, { alias = lastname, path = path })
		end
	end

	ui.calculate_padding(fzf_list)
	local formatted_list = {}
	for _, subdir in ipairs(fzf_list) do
		local formatted_ui = ui.format_directory_output(subdir, ui.max_path_len)
		table.insert(formatted_list, formatted_ui)
	end

	fzf_lua.fzf_exec(formatted_list, opts)
end
