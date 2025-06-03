local fzf_lua = require("fzf-lua")
local utils = require("extras.utils")

_G.select_commands = function(opts)
  opts = opts or {}
  opts.prompt = opts.prompt or "Select Command> "
  local home = os.getenv("HOME")
  local file = home .. "/shell/commands.txt"

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
    ["default"] = function(selected)
      local sel = selected[1]
      if sel:match("⟨(.-)⟩") then
        -- If path is inside parentheses, extract it
        sel = sel:match("⟨(.-)⟩")
      end
      print('DEBUGPRINT[2]: select_commands.lua:30: sel=' .. vim.inspect(sel))
      local task = require("overseer").new_task {
        name = sel,
        cmd = sel,
        on_exit = function(exit_code, output)
          -- Custom handling based on exit code and output
          if exit_code == 0 then
            print "Task completed successfully!"
          else
            print("Task failed with exit code " .. exit_code)
            print("Error output: " .. (output or "No output"))
          end
        end,
      }

      -- Start the task
      task:start()

      -- Toggle Overseer UI (optional)
      vim.cmd "OverseerToggle"
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
          local terminal_command = 'alacritty -e bash -c "'
              .. sel
              .. '; exec bash"'

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

-- _G.select_commands = function(opts)
--   utils.last_selected(select_commands)
--   opts = opts or {}
--   opts.prompt = "Scripts> "
--
--   opts.actions = {
--     ["default"] = {
--       fn = function(selected)
--         if type(selected) == "table" then
--           selected = table.concat(selected, " ")
--         end
--
--         print("DEBUGPRINT[187]: fzf.lua:1135: selected=" .. selected)
--
--         -- Ensure overseer is available
--         local success, overseer = pcall(require, "overseer")
--         if not success then
--           print "Error: 'overseer' module is not installed."
--           return
--         end
--
--         -- Create task
--         local task = require("overseer").new_task {
--           name = selected,
--           cmd = selected,
--           on_exit = function(exit_code, output)
--             -- Custom handling based on exit code and output
--             if exit_code == 0 then
--               print "Task completed successfully!"
--             else
--               print("Task failed with exit code " .. exit_code)
--               print("Error output: " .. (output or "No output"))
--             end
--           end,
--         }
--
--         -- Start the task
--         task:start()
--
--         -- Toggle Overseer UI (optional)
--         vim.cmd "OverseerToggle"
--       end,
--     },
--     ["tab"] = {
--       fn = function(selected)
--         if type(selected) == "table" then
--           selected = table.concat(selected, " ")
--         end
--
--         -- Execute the link directly based on the OS
--         if package.config:sub(1, 1) == "\\" then
--           -- For Windows, use 'start' or 'explorer' to open the URL (paste the link into the browser)
--           os.execute("start " .. selected)
--         else
--           -- Construct the terminal command to run
--           -- Construct the terminal command to run with alacritty
--           local terminal_command = 'alacritty -e bash -c "'
--             .. selected
--             .. '; exec bash"'
--
--           -- Open the terminal in Neovim and run the command
--           vim.cmd("term " .. terminal_command)
--         end
--       end,
--     },
--     ["ctrl-y"] = {
--       fn = function(selected)
--         local text = table.concat(selected, "\n")
--         vim.fn.setreg("+", text)
--         print("Command Copied: " .. text)
--       end,
--     },
--   }
--
--   -- Predefined array of popular links (with the base domain)
--   local scripts = {
--     "npm create vite@latest",
--     "bun create vite@latest",
--     "bun create next-app",
--     "npx sv create",
--     "bun install @tailwindcss/typography",
--     [[ Get-ChildItem -Path . -Recurse -Directory -Force -Include ".git" | Remove-Item -Recurse -Force ]],
--     "bun install",
--     "gh auth login",
--     "bun run dev --open",
--     "bun run dev",
--     "pnpm install",
--     "npm run dev",
--     "npm run build",
--     "npm run e2e",
--     "npm run test:e2e",
--     "npx shadcn@latest init",
--     "npx shadcn@latest add button",
--     "npx create-next-app@latest",
--   }
--
--   -- Execute fzf with the predefined popular links
--   fzf_lua.fzf_exec(scripts, opts)
-- end
