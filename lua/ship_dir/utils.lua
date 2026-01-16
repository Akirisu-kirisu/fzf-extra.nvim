
local H = require('ship_dir.handlers')

local function S()
	return require("ship_dir.directories")
end

local function utils()
	return require("ship_dir.utils")
end

local M = {}
--
function M.get_user_home()
	return os.getenv("HOME") or os.getenv("USERPROFILE") -- This will work for both Unix and Windows
end
--
M.home = M.get_user_home() or "unknown"

function M.get_last_name(path)
	-- Ensure the path is not empty or nil
	if not path or #path == 0 then
		return nil
	end

	-- Remove trailing slashes using Lua's string.gsub (will replace multiple slashes if needed)
	path = path:gsub("[\\/]+$", "")
	-- Use Lua pattern matching to extract the last part of the path after the last '/'

	-- Use Lua pattern matching to extract the last part of the path after the last '/'
	local name = path:match("([^\\/]+)$")

	-- Replace all dots in the name with underscores
	if name then
		return name:gsub("%.", "_")
	else
		return nil
	end
end

function M.get_second_last_name(path)
	-- Ensure the path is not empty or nil
	if not path or #path == 0 then
		return nil
	end

	-- Remove trailing slashes
	path = path:gsub("/+$", "")

	-- Extract all parts of the path into a table
	local parts = {}
	for part in path:gmatch("[^/]+") do
		table.insert(parts, part)
	end

	-- Debug: Print the extracted parts of the path
	-- print("Parts:", table.concat(parts, ", "))

	-- Return the second-to-last part if it exists
	if #parts >= 2 then
		-- Debug: Print the second-to-last part
		-- print("Second to last part:", parts[#parts - 1])
		return parts[#parts - 1]:gsub("%.", "_")
	else
		return nil
	end
end

function M.selected_path(selected)
    -- nothing selected or empty table
    if not selected or (type(selected) == "table" and #selected == 0) then
        return nil
    end

    -- if selected is a string
    if type(selected) == "string" then
        local path = selected[1]
        -- match ⟨…⟩ pattern
        local m = path:match("⟨(.-)⟩")
        if m then
            return m
        end
        -- remove leading icon if present
        path = path:gsub(" ", "")
        return path ~= "" and path or nil
    end

    -- if selected is a table
    if type(selected) == "table" then
        local path = selected[1]
        if not path or path == "" then
            return nil
        end

        -- match ⟨…⟩ pattern
        local m = path:match("⟨(.-)⟩")
        if m then
            path = m
        else
            -- remove leading icon if present
            path = path:gsub(" ", "")
        end

        return path ~= "" and path or nil
    end

    return nil
end

-- function M.selected_path(selected)
-- 	if not selected or (type(selected) == "table" and #selected == 0) then
--         return nil
--     end

-- 	local selected_path = selected[1]
-- 	if selected_path:match("⟨(.-)⟩") then
-- 		-- If path is inside parentheses, extract it
-- 		selected_path = selected_path:match("⟨(.-)⟩")
-- 	elseif selected_path:find(" ") then
-- 		-- If string starts with " ", remove it
-- 		selected_path = selected_path:gsub(" ", "")
-- 	end

-- 	-- local selected_path = selected[1]:match("%(([^)]+)%)") -- Capture the path inside parentheses
-- 	-- print("Selected_path: " .. vim.inspect(selected_path))

-- 	-- If no path is found inside parentheses, just use the selected string itself
-- 	if not selected_path then
-- 		selected_path = selected[1]
-- 	end
-- 	return selected_path
-- end
--
function M.is_windows()
	return package.config:sub(1, 1) == "\\"
end
--
-- function M.mapcombo(cmd_name, lua_func_str, keybind, mode, opts)
-- 	mode = mode or "n"
-- 	opts = vim.tbl_extend("force", { noremap = true, silent = true }, opts or {})
--
-- 	-- Create command
-- 	vim.cmd(string.format("command! -nargs=* %s lua %s", cmd_name, lua_func_str))
--
-- 	-- Create keybind
-- 	local func_ref = load("return " .. lua_func_str)() -- Convert string to function
-- 	vim.keymap.set(mode, keybind, func_ref, opts)
--
-- 	-- Ex:
-- 	-- mapcombo("lua", "_G.loud_search", "msr", "n", { silent = false }) -- visible output
-- end
--
function M.subdirs(directories)
	local unique_directories = {}
	local seen = {}

	for _, dir in ipairs(directories) do
		if dir.path and (not seen[dir.path] or dir.path:match("Current Dir")) and vim.fn.isdirectory(dir.path) == 1 then
			seen[dir.path] = true
			table.insert(unique_directories, dir)
		end
	end
	directories = unique_directories

	return directories
end

function M.get_current_dir(list)
	local current_dir = vim.fn.getcwd()
	local current_dir_name = vim.fn.fnamemodify(current_dir, ":t")

	-- Remove current_dir if it already exists in the list
	for i, entry in ipairs(list) do
		if entry.path == current_dir then
			table.remove(list, i)
			break
		end
	end

	-- Insert current_dir at the start of the list
	table.insert(list, 1, { path = current_dir, alias = current_dir_name })

	return list
end
--
function M.last_selected(name)
	local fn_name = name

	-- Mark previous fn as false
	if S().last_selected_fn and S().last_selected_fn ~= fn_name then
		S().last_selected_fn_status[S().last_selected_fn] = false
	end

	-- Mark current fn as true
	S().last_selected_fn_status[fn_name] = true
	S().last_selected_fn = fn_name
end
--

-- function M.path_exists(path)
--   return vim.fn.isdirectory(path) == 1
-- end
-- -- ───────────────────────────────────────────────────────────────────
-- -- ╭───────────────────────────────────────────────────────────────────╮
-- -- │ Actions                                                           │
-- -- ╰───────────────────────────────────────────────────────────────────╯
--
function M.open_dir(selected)
	local state = { current_back_index = 0 }
	local selected_path = M.selected_path(selected)
	if not selected_path then
		return print("Could not determine the directory from the selected string.")
	end

	if vim.fn.isdirectory(selected_path) == 1 then
		-- Change directory in Neovim
		vim.cmd("cd " .. vim.fn.fnameescape(selected_path))

		state.current_back_index = (state.current_back_index or 0) + 1
		if S().directories_temp_back[#S().directories_temp_back] ~= selected_path then
			table.insert(S().directories_temp_back, {path= selected_path, alias = state.current_back_index})
		end

		-- Inform zoxide
		vim.fn.system({ "zoxide", "add", selected_path })

		-- Update your custom history
		S().directories_history[selected_path] = true
		if M.write_history then
			M.write_history(S().directories_history)
		end

		print("Changed directory to: " .. selected_path)

		-- Call the custom function
		local success, err = pcall(H.DirLocal)
		if not success then
			print("Error running fzf_dirs_local: " .. err)
		else
			-- print("Successfully Changed Directories: " .. selected_path)
		end
	else
		print("Directory does not exist: " .. selected_path)
	end
end

function M.open_dir_tmux(selected)
	local selected_path = M.selected_path(selected)
  print('DEBUGPRINT[229]: utils.lua:248: selected_path=' .. vim.inspect(selected_path))

	local tmux_session_name

	-- Handle root directory case
	if selected_path == "/" then
		tmux_session_name = "root"
	else
		tmux_session_name = M.get_last_name(selected_path) -- Use directory name as tmux session name
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
			-- locl tmux_session_exists = vim.fn.system("tmux has-session -t " .. tmux_session_name)

			-- if string.find(tmux_session_exists, "can't find session: " .. tmux_session_name) then
			-- tmux_session_name = utils.get_last_name(selected_path) -- Use directory name as tmux session name
			-- vim.fn.system("tmux new-session -d -s " .. tmux_session_name .. ' "cd ' .. selected_path .. '; bash"')
			-- else
			-- Attach to the tmux session
			-- vim.fn.system("tmux attach -t " .. tmux_session_name)
			--
			-- -- Switch to the tmux client (optional)
			-- vim.fn.system("tmux switch-client -t " .. tmux_session_name)

			-- TODO:
			-- Session exists, check if the path matches
			-- local current_path = vim.fn.system("tmux display-message -p '#{pane_current_path}'")
			-- current_path = current_path:gsub("\n", "") -- Remove any extra newlines from the output
			-- Get the current path of the active pane in the specified tmux session
			-- local panes_list = vim.fn.system("tmux list-panes -t " .. tmux_session_name)
			--
			-- local current_path = vim.fn.system("tmux display-message -p '#{pane_current_path}' -t " .. tmux_session_name .. ":0.0")
			-- current_path = current_path:gsub("\n", "")  -- Remove newlines from the output
			-- print("DEBUGPRINT[269]: actions.lua:98: current_path=" .. vim.inspect(current_path))

			-- before creating a new one make sure it has different path
			-- if selected_path then
			-- 	-- body
			-- end
			-- local last_name = utils.get_last_name(selected_path) -- Use directory name as tmux session name
			-- local tmux_sesson_identifier = utils.get_second_last_name(selected_path)
			-- tmux_session_name = tmux_sesson_identifier .. "/" .. last_name
			-- end

			-- local last_name = utils.get_last_name(selected_path)
			-- local tmux_sesson_identifier = utils.get_second_last_name(selected_path)
			-- tmux_session_name = tmux_sesson_identifier .. "/" .. last_name

			-- Create new tmux session
			local tmux_sessions = vim.fn.systemlist("tmux list-sessions -F '#S'")
			local session_exists = false
			for _, session in ipairs(tmux_sessions) do
				if session == tmux_session_name then
					session_exists = true
					break
				end
			end

			if session_exists then
				local choice =
					vim.fn.input("Session '" .. tmux_session_name .. "' already exists. [s]witch, [c]reate new? ")

				if choice == "s" then
					-- Switch to existing session
					vim.fn.system("tmux switch-client -t " .. tmux_session_name)
					vim.fn.system({ "zoxide", "add", selected_path })
				elseif choice == "c" then
					local sub_choice = vim.fn.input("Create new session: [a]utomatic or [m]anual name? ")

					if sub_choice == "a" then
						local last_name = M.get_last_name(selected_path)
						local tmux_sesson_identifier = M.get_second_last_name(selected_path)
						local auto_name = tmux_sesson_identifier .. "/" .. last_name

						vim.fn.system("tmux new-session -d -s " .. auto_name .. ' "cd ' .. selected_path .. '; bash"')
						vim.fn.system({ "zoxide", "add", selected_path })
						vim.fn.system("tmux switch-client -t " .. auto_name)
					elseif sub_choice == "m" then
						local new_name = vim.fn.input("Enter new session name: ")
						if new_name ~= "" then
							vim.fn.system(
								"tmux new-session -d -s " .. new_name .. ' "cd ' .. selected_path .. '; bash"'
							)
							vim.fn.system({ "zoxide", "add", selected_path })
							vim.fn.system("tmux switch-client -t " .. new_name)
						else
							print("No session name provided. Aborting.")
						end
					else
						print("Invalid choice. Aborting.")
					end
				else
					print("Invalid choice. Aborting.")
				end
			else
				-- Create and switch to the session if it doesn't already exist
				vim.fn.system("tmux new-session -d -s " .. tmux_session_name .. ' "cd ' .. selected_path .. '; bash"')
				vim.fn.system({ "zoxide", "add", selected_path })
				vim.fn.system("tmux attach -t " .. tmux_session_name)
				vim.fn.system("tmux switch-client -t " .. tmux_session_name)
			end

			-- vim.fn.system("tmux new-session -d -s " .. tmux_session_name .. ' "cd ' .. selected_path .. '; bash"')
			-- vim.fn.system({ "zoxide", "add", selected_path })
			--
			-- vim.fn.system("tmux switch-client -t " .. tmux_session_name)
			-- print("Switched to existing session: " .. tmux_session_name)
			-- -- Attach to the tmux session
			-- vim.fn.system("tmux attach -t " .. tmux_session_name)

			-- Switch to the tmux client (optional)
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
		-- print("Changed directory to: " .. selected_path)
	end

	if vim.g.neovide then
		vim.cmd("cd " .. selected_path)
		-- print("Changed directory to: " .. selected_path)
	end
end


function M.captures_parentheses_copy(selected)
	-- print('DEBUGPRINT[202]: actions.lua:156: selected=' .. vim.inspect(selected))
	local selected_path = M.selected_path(selected)
	local output = vim.fn.setreg("+", selected_path)
	print("Path Copied" .. selected_path)
	return output
end
--

function M.open_oil(selected)
	local selected_path = utils().selected_path(selected)

	if not selected_path then
		return print("Could not determine the directory from the selected string.")
	end

	if vim.fn.isdirectory(selected_path) == 1 then
		S().directories_history[selected_path] = true
		if M.write_history then
			M.write_history(S().directories_history)
		end
		vim.cmd("Oil " .. selected_path)
		-- print("Changed directory to: " .. selected_path)
	else
		print("Directory does not exist: " .. selected_path)
	end
end

function M.horizontal(selected)
	local selected_path = utils().selected_path(selected)
	-- Open a horizontal split
	vim.cmd("split")

	-- Use Oil to open the selected location
	-- 'selected[1]' is the selected path from fzf-lua
	vim.cmd("Oil " .. vim.fn.fnameescape(selected_path))
end
--
function M.vertical(selected)
	local selected_path = utils().selected_path(selected)
	-- Open a horizontal split
	local old_splitright = vim.o.splitright
	vim.o.splitright = true
	vim.cmd("vsplit")
	vim.o.splitright = old_splitright

	-- Use Oil to open the selected location
	-- 'selected[1]' is the selected path from fzf-lua
	vim.cmd("Oil " .. vim.fn.fnameescape(selected_path))
end
--
-- -- ╭───────────────────────────────────────────────────────────────────╮
-- -- │ history utls                                                      │
-- -- ╰───────────────────────────────────────────────────────────────────╯
function M.push_recent_dir(dir)
  local recent = S().recent_dirs or {}
  local new = { dir }

  -- Remove duplicates
  for _, d in ipairs(recent) do
    if d ~= dir then
      table.insert(new, d)
    end
  end

  -- Keep only last 2
  while #new > 2 do
    table.remove(new)
  end

  S().recent_dirs = new
end

-- function M.normalize_selection(sel)
--   -- Remove any leading non-path junk (icons, markers, spaces)
--   return sel:gsub("^%s*[^/%w~.-]+%s*", "")
-- end
function M.get_selected_string(selected)
  if type(selected) == "string" then
    return selected
  end

  if type(selected) == "table" then
    return selected[1]
  end

  return nil
end

function M.normalize_selection(sel)
  if type(sel) ~= "string" then
    return nil
  end

  -- Remove anything before the path (/ or ~)
  return sel:gsub("^.-(%f[/~])", "%1")
end

function M.read_zoxide_scored()
  local dirs = {}

  -- zoxide query -ls => "<score>\t<path>"
  local handle = io.popen("zoxide query -ls 2>/dev/null")
  if not handle then
    return dirs
  end

  for line in handle:lines() do
    local score, path = line:match("^(%S+)%s+(.+)$")
    if score and path then
      path = vim.fn.expand(path):gsub("/+$", "")
      if vim.fn.isdirectory(path) == 1 then
        dirs[path] = tonumber(score) or 0
      end
    end
  end

  handle:close()
  return dirs
end

M.history_file = vim.fn.stdpath "cache" .. "/dirs_history.txt"

function M.read_history()
  local dirs = {}
  local seen = {}

  local file = io.open(M.history_file, "r")
  if file then
    for line in file:lines() do
      line = vim.fn.expand(line):gsub("/+$", "") -- Normalize
      if vim.fn.isdirectory(line) == 1 and not seen[line] then
        dirs[line] = true
        seen[line] = true
      end
    end
    file:close()
  end

  return dirs
end


function M.write_history(dirs)
  local file = io.open(M.history_file, "w")
  if file then
    for dir, _ in pairs(dirs) do
      file:write(dir .. "\n")
    end
    file:close()
  else
    print "⚠ Could not open history file for writing."
  end
end
--
function M.add_current_dir_to_history()
  local cwd = vim.fn.getcwd()
  if vim.fn.isdirectory(cwd) == 1 then
    S().directories_history[cwd] = true
  end
end

vim.api.nvim_create_autocmd({ "VimLeavePre", "DirChanged" }, {
  callback = M.add_current_dir_to_history,
})

S().directories_history = M.read_history()
-- 👇 Ensure any changes during session are written at exit
vim.api.nvim_create_autocmd("VimLeavePre", {
  callback = function()
    M.write_history(S().directories_history)
  end,
})

return M
