local fzf_lua = require("fzf-lua")
local utils = require("extras.utils")

_G.select_terminal_commands = function(opts)
	opts = opts or {}
	opts.prompt = opts.prompt or "Select Command> "
	local home = os.getenv("HOME")
	local file = home .. "/.shell/commands.txt"

	-- Read and parse commands file into a table of { display = ..., cmd = ... }
	local lines = {}
	for line in io.lines(file) do
		-- Line format: ⟨command⟩│description
		-- Extract command inside ⟨...⟩ and description after │
		local cmd, desc = line:match("⟨(.-)⟩│(.*)")
		if cmd then
			cmd = cmd:gsub("^%s*(.-)%s*$", "%1") -- trim spaces
			desc = desc and desc:gsub("^%s*(.-)%s*$", "%1") or ""
			-- Format display line similar to your Bash: icon + padded command + desc
			local display = string.format(" %-60s  %s", "⟨" .. cmd .. "⟩", desc)
			table.insert(lines, { display = display, cmd = cmd })
		end
	end

	opts.actions = {
		["alt-m"] = {
			fn = function(selected)
				_G.select_main_menu_mfs()
			end,
			exec_silent = true,
		},
		["default"] = function(selected)
			local sel = selected[1]
			if sel:match("⟨(.-)⟩") then
				-- If path is inside parentheses, extract it
				sel = sel:match("⟨(.-)⟩")
			end
			local task = require("overseer").new_task({
				name = sel,
				cmd = sel,
				on_exit = function(exit_code, output)
					-- Custom handling based on exit code and output
					if exit_code == 0 then
						print("Task completed successfully!")
					else
						print("Task failed with exit code " .. exit_code)
						print("Error output: " .. (output or "No output"))
					end
				end,
			})

			-- Start the task
			task:start()

			-- Toggle Overseer UI (optional)
			vim.cmd("OverseerToggle")
			-- Find cmd by display
		end,
		["tab"] = {
			fn = function(selected)
				local sel = selected[1]
				if sel:match("⟨(.-)⟩") then
					-- If path is inside parentheses, extract it
					sel = sel:match("⟨(.-)⟩")
				end

				-- Execute the link directly based on the OS
				if package.config:sub(1, 1) == "\\" then
					-- For Windows, use 'start' or 'explorer' to open the URL (paste the link into the browser)
					os.execute("start " .. sel)
				else
					-- Construct the terminal command to run
					-- Construct the terminal command to run with alacritty
					local terminal_command = 'alacritty -e bash -c "' .. sel .. '; exec bash"'

					-- Open the terminal in Neovim and run the command
					vim.cmd("term " .. terminal_command)
				end
			end,
		},
		["ctrl-y"] = {
			fn = function(selected)
				local sel = selected[1]
				if sel:match("⟨(.-)⟩") then
					-- If path is inside parentheses, extract it
					sel = sel:match("⟨(.-)⟩")
				end
				-- local text = table.concat(sel, "\n")
				vim.fn.setreg("+", sel)
				print("Command Copied: " .. sel)
			end,
		},
	}
	local entries = {}
	for _, entry in ipairs(lines) do
		table.insert(entries, entry.display)
	end

	-- Use fzf-lua to pick from entries
	fzf_lua.fzf_exec(entries, opts)
end

_G.select_nvim_commands = function(opts)
	opts = opts or {}
	opts.prompt = "Regex Rename> "

	-- Regex snippets with descriptions
	local scripts = {
		{ cmd = "'<,'>s/\\v(\\w+)\\s*=\\s*(\\w+)/\\2 = \\1/g", desc = "Swap LHS and RHS of assignments" },
		{ cmd = "'<,'>s/\\v(.*):\\s*(.*)/\\2: \\1/g", desc = "Swap colon-separated key-value pairs" },
		{ cmd = "'<,'>s/\\v(\\d{4})-(\\d{2})-(\\d{2})/\\3\\/\\2\\/\\1/g", desc = "YYYY-MM-DD to DD/MM/YYYY" },
	}

	-- Format each item for display in fzf
	local display_items = vim.tbl_map(function(item)
		return string.format("%s | %s", item.cmd, item.desc)
	end, scripts)

	-- Define action on selection
	opts.actions = {
        ["alt-m"] = {
			fn = function(selected)
				_G.select_main_menu_mfs()
			end,
			exec_silent = true,
		},
		["default"] = function(selected)
			local cmd = selected[1]:match("^(.-)%s+|")
			if cmd then
				vim.cmd("vnew") -- open vertical split
				vim.api.nvim_buf_set_lines(0, 0, -1, false, {
					"-- Edit and run this regex in visual mode",
					cmd,
				})
				vim.bo.buftype = "nofile"
				vim.bo.bufhidden = "wipe"
				vim.bo.swapfile = false
				vim.bo.filetype = "vim"
			end
		end,
	}

	fzf_lua.fzf_exec(display_items, opts)
end
