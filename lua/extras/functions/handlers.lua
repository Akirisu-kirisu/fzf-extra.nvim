local actions = require("fzf-lua.actions")
local fzf_lua = require("fzf-lua")
local utils = require("extras.utils")
local ui = require("extras.ui")
local extra_actions = require("extras.actions")

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
require("extras.functions.main_menu_devices_mfd.test")

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
		["tab"] = function(selected, opts)
			extra_actions.open_dir_tmux(selected)
		end,
	}

	utils.get_current_dir(_G.directories)

	utils.subdirs(_G.directories)

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
		elseif selected[1] == "test" then
			_G.select_hardDisk()
        -- elseif selected[1] == "Hard Disk Subdir" then

          -- _G.fzf_devices_dirs_subdir()
          -- If "Links" is selected, you can add code to handle that case here
        elseif selected[1] == "Removable Storage" then
			_G.select_removable_devices()
          -- If "Links" is selected, you can add code to handle that case here
        end
      end,
    },
  }

  -- Define the choices for the fzf menu
  local choices = { "Hard Disk", "Hard Disk Subdir", "Removable Storage", 'test' }

  -- Open fzf for selecting between "Links" or "Git Repos"
  fzf_lua.fzf_exec(choices, opts)
end

return M
