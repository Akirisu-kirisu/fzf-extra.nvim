local M = {}

function M.get_user_home()
  return os.getenv "HOME" or os.getenv "USERPROFILE" -- This will work for both Unix and Windows
end

local home = M.get_user_home()

function M.get_last_name(path)
  -- Ensure the path is not empty or nil
  if not path or #path == 0 then
    return nil
  end
  -- Remove trailing slashes using Lua's string.gsub (will replace multiple slashes if needed)
  path = path:gsub("/+$", "")
  -- Use Lua pattern matching to extract the last part of the path after the last '/'

  -- Use Lua pattern matching to extract the last part of the path after the last '/'
  local name = path:match "([^/]+)$"

  -- Replace all dots in the name with underscores
  if name then
    return name:gsub("%.", "_")
  else
    return nil
  end
end

function M.selected_path(selected)
  local selected_path = selected[1]:match "%(([^)]+)%)" -- Capture the path inside parentheses
  print("Selected_path: " .. vim.inspect(selected_path))

  -- If no path is found inside parentheses, just use the selected string itself
  if not selected_path then
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
    if
      dir.path
      and (not seen[dir.path] or dir.path:match("Current Dir"))
      and vim.fn.isdirectory(dir.path) == 1
    then
      seen[dir.path] = true
      table.insert(unique_directories, dir)
    end
  end

  _G.directories = unique_directories

  return _G.directories
end

function M.get_current_dir(list)
-- Include the current working directory as a "marked" directory (temporary)
	local current_dir = vim.fn.getcwd()

	-- Dynamically set the alias for the current directory to its name
	local current_dir_name = vim.fn.fnamemodify(current_dir, ":t") -- This gets the last part of the directory path (i.e., the name of the directory)
	-- local current_dir_name = current_dir_name .. " (" .. current_dir .. ")"

	-- Insert the current directory entry with the dynamically set alias
	return table.insert(list, { path = current_dir, alias = current_dir_name })
end

return M
