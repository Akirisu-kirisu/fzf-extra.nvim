local fzf_lua = require("fzf-lua")
local utils = require("extras.utils")

_G.select_git_repo = function(opts)
	utils.last_selected(select_git_repo)
	opts = opts or {}
	opts.prompt = "Git Repos> "
	opts.fn_transform = function(repo)
		-- Highlight repo names in yellow for example
		return fzf_lua.utils.ansi_codes.yellow(repo)
	end
	-- Helper function to get GitHub username
	local function get_github_username()
		local username_command = "gh api user -q .login"
		local handle = io.popen(username_command)
		local username = handle:read("*a"):gsub("%s+", "") -- Remove any extra whitespace
		handle:close()
		return username
	end

	-- Helper function to check if ssh-agent is running
	local function is_ssh_agent_running()
		local check_ssh_agent_command = "ps aux | grep sshd"
		local handle = io.popen(check_ssh_agent_command)
		local ssh_agent_process = handle:read("*a"):gsub("%s+", "") -- Read the process list output
		handle:close()
		return #ssh_agent_process > 0
	end

	-- Remove the leading and trailing quotes if they exist
	local function remove_quotes(str)
		return str:match("^[\"'](.-)[\"']$") or str
	end

	-- List of custom repositories (add as many as you like here)
	local custom_repos = {
		"Immership/academy",
		"stevearc/oil.nvim",
	}
	-- Helper function to construct the git clone URL
	local function get_clone_url(username, repo)
		-- Check if we are on Windows
		if package.config:sub(1, 1) == "\\" then
			-- Windows uses HTTPS
			if repo:match("/") then
				return "https://github.com/" .. remove_quotes(repo)
			else
				return "https://github.com/" .. username .. "/" .. repo .. ".git"
			end
		else
			-- Unix-based OS: use SSH if agent is running, else use HTTPS
			local use_ssh = is_ssh_agent_running()
			if use_ssh then
				-- List of custom repositories (add as many as you like here)
				if repo:match("/") then
					-- If the repository belongs to the user, use the username for the clone URL
					return "git@github.com:" .. repo .. ".git"
				else
					-- Otherwise, it's a public repo (no username specified)
					return "git@github.com:" .. username .. "/" .. repo .. ".git"
				end
			else
				return "https://github.com/" .. username .. "/" .. repo .. ".git"
			end
		end
	end
	opts.actions = {
        ["alt-m"] = {
			fn = function(selected)
				_G.select_main_menu_mfs()
			end,
			exec_silent = true,
		},
		["default"] = {
			fn = function(selected)
				-- Get the GitHub username
				local username = get_github_username()

				-- Get the selected repository (in the form 'owner/repo')
				local repo = selected[1]

				-- If no repo selected, use the custom repositories
				if not repo or repo == "" then
					repo = custom_repos[1] -- Default to the first custom repo
				end

				-- Get the correct git clone URL
				local clone_url = get_clone_url(username, repo)

				-- Run the git clone command
				local result = "git clone " .. clone_url
				-- Run the command using vim.fn.system to capture the output
				-- local result = vim.fn.system(cmd)
				local task = require("overseer").new_task({
					name = result,
					cmd = result,
				})
				task:start()
				vim.cmd("OverseerToggle")
			end,
		},
		["tab"] = {
			fn = function(selected)
				-- Get the GitHub username
				local username = get_github_username()

				-- Get the selected repository (in the form 'owner/repo')
				local repo = selected[1]

				-- If no repo selected, use the custom repositories
				if not repo or repo == "" then
					repo = custom_repos[1] -- Default to the first custom repo
				end

				-- Get the correct git clone URL
				local clone_url = get_clone_url(username, repo)

				-- Run the git clone command
				local cmd = "git clone " .. clone_url
				-- Run the command using vim.fn.system to capture the output
				local result = vim.fn.system(cmd)

				-- Check if the command was successful
				if vim.v.shell_error ~= 0 then
					print("Failed to clone repository. Error: " .. result)
				else
					print("Cloning repository was successful.")
				end
			end,
			exec_silent = true,
		},
		["ctrl-y"] = {
			fn = function(selected)
				local text = table.concat(selected, "\n")
				vim.fn.setreg("+", text)
				print("Command Copied: " .. text)
			end,
		},
	}
	-- Fetch GitHub repos using 'gh' CLI command
	-- Modify `gh repo list` with the appropriate flags (e.g., private repos, number of repos)

	local command
	if package.config:sub(1, 1) == "\\" then
		command = [[ gh repo list --limit 100 --json name,owner | jq -r ".[] | .name" ]]
	else
		command =
			[[ gh repo list --limit 100 --json name,owner | grep -oP '\"name\":\s*\"[^\"]+\"' | awk -F '\"' '{print $4}' ]]
	end

	-- Combine the list of GitHub repos with the custom repositories (add them to the list)
	local combined_command = command
	for _, repo in ipairs(custom_repos) do
		combined_command = combined_command .. " && echo " .. repo
	end

	-- Execute the command and feed the results into fzf
	fzf_lua.fzf_exec(combined_command, opts)
end
