local actions = require("fzf-lua.actions")
local fzf_lua = require("fzf-lua")
local utils = require("extras.utils")
local ui = require("extras.ui")
local extra_actions = require("extras.actions")

_G.select_search_current_dir_packages = function(opts)
	utils.last_selected(select_search_current_dir_packages)
	opts = opts or {}
	opts.prompt = "Scripts> " -- typo fixed: promt -> prompt

	local scratch_pad = ""
	opts.actions = {
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

-- _G.select_search_current_dir_packages = function()
-- 	local package_json_path = vim.fn.getcwd() .. "/package.json"
--
-- 	local opts = {
-- 		fzf_opts = {
-- 			["--preview"] = string.format(
-- 				[[
--     bash -c 'dep=$(echo {} | cut -d ":" -f1 | tr -d " "); rg --context 5 --heading --line-number --color=always "\"$dep\"" %q'
--   ]],
-- 				package_json_path
-- 			),
-- 			["--preview-window"] = "right:60%:wrap",
-- 		},
-- 		prompt = "Packages> ",
-- 	}
--
-- 	local items = { "vite: ^4.0.0", "react: ^18.2.0" }
--
-- 	require("fzf-lua").fzf_exec(items, opts)
-- end
