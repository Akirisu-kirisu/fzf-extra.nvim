local fzf_lua = require("fzf-lua")
local utils = require("extras.utils")

_G.select_commands = function(opts)
  utils.last_selected(select_commands)
  opts = opts or {}
  opts.prompt = "Scripts> "

  opts.actions = {
    ["default"] = {
      fn = function(selected)
        if type(selected) == "table" then
          selected = table.concat(selected, " ")
        end

        print("DEBUGPRINT[187]: fzf.lua:1135: selected=" .. selected)

        -- Ensure overseer is available
        local success, overseer = pcall(require, "overseer")
        if not success then
          print "Error: 'overseer' module is not installed."
          return
        end

        -- Create task
        local task = require("overseer").new_task {
          name = selected,
          cmd = selected,
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
      end,
    },
    ["tab"] = {
      fn = function(selected)
        if type(selected) == "table" then
          selected = table.concat(selected, " ")
        end

        -- Execute the link directly based on the OS
        if package.config:sub(1, 1) == "\\" then
          -- For Windows, use 'start' or 'explorer' to open the URL (paste the link into the browser)
          os.execute("start " .. selected)
        else
          -- Construct the terminal command to run
          -- Construct the terminal command to run with alacritty
          local terminal_command = 'alacritty -e bash -c "'
            .. selected
            .. '; exec bash"'

          -- Open the terminal in Neovim and run the command
          vim.cmd("term " .. terminal_command)
        end
      end,
    },
    ["ctrl-y"] = {
      fn = function(selected)
        local text = table.concat(selected, "\n")
        vim.fn.setreg("+", text)
        print("Command Copied: " .. text)
      end,
    },
  }

  -- Predefined array of popular links (with the base domain)
  local scripts = {
    "npm create vite@latest",
    "bun create vite@latest",
    "bun create next-app",
    "npx sv create",
    "bun install @tailwindcss/typography",
    [[ Get-ChildItem -Path . -Recurse -Directory -Force -Include ".git" | Remove-Item -Recurse -Force ]],
    "bun install",
    "gh auth login",
    "bun run dev --open",
    "bun run dev",
    "pnpm install",
    "npm run dev",
    "npm run build",
    "npm run e2e",
    "npm run test:e2e",
    "npx shadcn@latest init",
    "npx shadcn@latest add button",
    "npx create-next-app@latest",
  }

  -- Execute fzf with the predefined popular links
  fzf_lua.fzf_exec(scripts, opts)
end
