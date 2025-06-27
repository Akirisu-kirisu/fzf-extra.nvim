-- local mappings = {
-- 	{
-- 		cmd = "Directories",
-- 		func = "select_directory_global_mfe",
-- 		key = "mxe",
-- 		description = "Select global directory for MFE",
-- 	},
-- 	{ cmd = "Directories", func = "select_main_menu_mfs", key = "mxs", description = "Select main menu for MFS" },
-- 	{
-- 		cmd = "Directories",
-- 		func = "main_menu_devices_mfd",
-- 		key = "mxd",
-- 		description = "Select main menu for devices MFD",
-- 	},
-- 	{ cmd = "Directories", func = "select_filePath", key = "mxc", description = "Select file path" },
-- 	{ cmd = "Directories", func = "select_local_directories", key = "mxw", description = "Select local directories" },
-- 	{ cmd = "Directories", func = "select_hidden_directories", key = "mxh", description = "Select hidden directories" },
-- 	{
-- 		cmd = "Directories",
-- 		func = "select_history_directories",
-- 		key = "mxi",
-- 		description = "Select history directories",
-- 	},
-- }

local mappings = {
	{
		cmd = "Directories",
		func = "select_directory_global_mfe",
		key = "mfe",
		description = "Select global directory for MFE",
	},
	{ cmd = "Directories", func = "select_main_menu_mfs", key = "mfs", description = "Select main menu for MFS" },
    { cmd = "Directories", func = "select_terminal_history", key = "<leader>fh", description = "Select main menu for MFS" },
	{
		cmd = "Directories",
		func = "main_menu_devices_mfd",
		key = "mfd",
		description = "Select main menu for devices MFD",
	},
	{ cmd = "Directories", func = "select_filePath", key = "<leader>fc", description = "Select file path" },
	{ cmd = "Directories", func = "select_git_commits", key = "mxe", description = "Select file path" },
	{ cmd = "Directories", func = "select_local_directories_max_1", key = "mfw", description = "Select local directories" },
	{ cmd = "Directories", func = "select_local_directories", key = "<leader>fw", description = "Select local directories" },
	{ cmd = "Directories", func = "select_hidden_directories", key = "mfh", description = "Select hidden directories" },
	{
		cmd = "Directories",
		func = "select_history_directories",
		key = "mfi",
		description = "Select history directories",
	},
}

vim.keymap.set('n', 'mfl', function()
	if type(_G.last_selected_fn) == "function" then
		_G.last_selected_fn()
	else
		vim.notify("No function selected!", vim.log.levels.WARN)
	end
end, { desc = "Run last selected directory picker" })

for _, mapping in ipairs(mappings) do
	-- Check if the function is globally available
	local func = _G[mapping.func]
	if func then
		-- Register the command
		vim.cmd(string.format([[command! -nargs=* %s lua %s()]], mapping.cmd, mapping.func))

		-- Set the keybind and print description
		vim.keymap.set("n", mapping.key, function()
			print("Executing: " .. mapping.description)
			func() -- Execute the function
		end, {desc = mapping.description})
	else
		-- Print an error message if the function is not found
		print("Error: Function '" .. mapping.func .. "' is not defined.")
	end
end
