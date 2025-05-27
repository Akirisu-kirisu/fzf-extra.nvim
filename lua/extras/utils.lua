local M = {}

function M.get_user_home()
	return os.getenv("HOME") or os.getenv("USERPROFILE") -- This will work for both Unix and Windows
end

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
	print("Parts:", table.concat(parts, ", "))

	-- Return the second-to-last part if it exists
	if #parts >= 2 then
		-- Debug: Print the second-to-last part
		print("Second to last part:", parts[#parts - 1])
		return parts[#parts - 1]:gsub("%.", "_")
	else
		return nil
	end
end

-- function M.selected_path(selected)
-- 	local selected_path = selected[1]
--
-- 	if selected_path:match("%(([^)]+)%)") then
-- 		-- If path is inside parentheses, extract it
-- 		selected_path = selected_path:match("%(([^)]+)%)")
-- 	elseif selected_path:find(" ") then
-- 		-- If string starts with " ", remove it
-- 		selected_path = selected_path:gsub(" ", "")
-- 	end
--
-- 	-- local selected_path = selected[1]:match("%(([^)]+)%)") -- Capture the path inside parentheses
-- 	-- print("Selected_path: " .. vim.inspect(selected_path))
--
-- 	-- If no path is found inside parentheses, just use the selected string itself
-- 	if not selected_path then
-- 		selected_path = selected[1]
-- 	end
-- 	return selected_path
-- end
function M.selected_path(selected)
	local selected_path = selected[1]

	-- Match the outermost parentheses
	if selected_path:match("^%b()$") then
		-- If the entire string is wrapped in parentheses
		selected_path = selected_path:sub(2, -2)
	else
		-- Try to find the longest match that starts with '(' and ends with ')'
		local start_pos, end_pos = selected_path:find("%b()")
		if start_pos and end_pos then
			selected_path = selected_path:sub(start_pos + 1, end_pos - 1)
		end
	end

	-- If string starts with " ", remove it
	if selected_path:find(" ") then
		selected_path = selected_path:gsub(" ", "")
	end

	-- Fallback: use original string
	if not selected_path or selected_path == "" then
		selected_path = selected[1]
	end

	return selected_path
end

function M.is_windows()
	return package.config:sub(1, 1) == "\\"
end

function M.mapcombo(cmd_name, lua_func_str, keybind, mode, opts)
	mode = mode or "n"
	opts = vim.tbl_extend("force", { noremap = true, silent = true }, opts or {})

	-- Create command
	vim.cmd(string.format("command! -nargs=* %s lua %s", cmd_name, lua_func_str))

	-- Create keybind
	local func_ref = load("return " .. lua_func_str)() -- Convert string to function
	vim.keymap.set(mode, keybind, func_ref, opts)

	-- Ex:
	-- mapcombo("lua", "_G.loud_search", "msr", "n", { silent = false }) -- visible output
end

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
	-- Include the current working directory as a "marked" directory (temporary)
	local current_dir = vim.fn.getcwd()

	-- Dynamically set the alias for the current directory to its name
	local current_dir_name = vim.fn.fnamemodify(current_dir, ":t") -- This gets the last part of the directory path (i.e., the name of the directory)

	-- Check if the path already exists in the list
	for _, entry in ipairs(list) do
		if entry.path == current_dir then
			-- If the path exists, return the list without modification
			return list
		end
	end

	-- Insert the current directory entry with the dynamically set alias
	table.insert(list, { path = current_dir, alias = current_dir_name })
	return list
end

return M
