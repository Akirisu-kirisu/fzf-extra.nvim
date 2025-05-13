local utils = require("extras.utils")
local history_utils = require("extras.history-utils.history-utils")

local M = {}

function M.open_dir(selected)
	local selected_path = utils.selected_path(selected)

	if not selected_path then
		return print("Could not determine the directory from the selected string.")
	end

	if vim.fn.isdirectory(selected_path) == 1 then
		vim.cmd("cd " .. vim.fn.fnameescape(selected_path))

		_G.directories_history[selected_path] = true
		if history_utils.write_history then
			history_utils.write_history(_G.directories_history)
		end

		print("Changed directory to: " .. selected_path)
		local success, err = pcall(_G.select_directory_local_a_m)

		if not success then
			print("Error running fzf_dirs_local: " .. err)
		else
			print("Successfully Changed Directories: " .. selected_path)
		end
	else
		print("Directory does not exist: " .. selected_path)
	end

	-- local current_dir = vim.fn.getcwd()
	-- if selected_path == current_dir then
	-- 	return print("Already in the target directory: " .. selected_path)
	-- end

	-- vim.cmd("cd " .. vim.fn.fnameescape(selected_path))
	-- print("Changed directory to: " .. selected_path)
	--
	-- local ok, err = pcall(_G.select_directory_local_a_m)
	-- if not ok then
	-- 	print("Error running fzf_mfe: " .. err)
	-- else
	-- 	print("Successfully changed directories: " .. selected_path)
	-- end
end

function M.open_dir_tmux(selected)
	local selected_path
	-- selected_path = utils.selected_path(selected) -- Pass the cleaned path to your function
	local captured_path = selected[1]:match("%(([^)]+)%)")
	if captured_path then
		selected_path = utils.selected_path(selected)
	else
		selected_path = selected[1]:gsub(" ", "") -- Remove the " " prefix
	end

	local tmux_session_name

	-- Handle root directory case
	if selected_path == "/" then
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
			local tmux_session_exists = vim.fn.system("tmux has-session -t " .. tmux_session_name .. ">/dev/null 2>&1")

			-- print(
			--   "DEBUGPRINT[1]: fzf.lua:376: tmux_session_exists="
			--     .. tmux_session_exists
			-- )
			vim.fn.system("tmux new-session -d -s " .. tmux_session_name .. ' "cd ' .. selected_path .. '; bash"')

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
end

function M.captures_parentheses_copy(selected)
	-- print('DEBUGPRINT[202]: actions.lua:156: selected=' .. vim.inspect(selected))
	local selected_path = utils.selected_path(selected)
	local output = vim.fn.setreg("+", selected_path)
	print("Path Copied" .. selected_path)
	return output
end

return M
