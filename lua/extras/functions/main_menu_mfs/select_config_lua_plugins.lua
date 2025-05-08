local fzf_lua = require("fzf-lua")
local utils = require("extras.utils")
local home = utils.get_user_home()

_G.select_configuration_lua_plugins = function(opts)
  opts = opts or {}
  opts.prompt = "Plugin Links> "

  local plugin_file

  if utils.is_windows() then
    -- For Windows, construct path using home
    plugin_file = home .. "\\AppData\\Local\\nvim\\lua\\plugins\\init.lua"
  else
    -- For Unix-like systems, use this path
    plugin_file = home .. "/.config/nvim/lua/plugins/init.lua"
  end

  opts.actions = {
    ["tab"] = {
      fn = function(selected)
        -- Get the selected dependency name from the FZF result
        local dep = selected[1]

        -- Build the full path to the package.json file in the current working directory
        -- local package_json = vim.fn.getcwd() .. "/package.json"

        -- Prepare the ripgrep command to search for the dependency in package.json
        -- This looks for lines like: "react": "^18.2.0"
        local quote = [[""]]
        local rg_cmd
        if package.config:sub(1, 1) == "\\" then
          rg_cmd = "rg --line-number "
            .. quote
            .. dep
            .. quote
            .. " "
            .. quote
            .. plugin_file
            .. quote
        else
          rg_cmd = "rg --line-number '\""
            .. dep
            .. '"\' "'
            .. plugin_file
            .. '"'
        end

        -- Execute the ripgrep command and read the output
        local handle = io.popen(rg_cmd)
        local result = handle and handle:read "*a" or ""
        if handle then
          handle:close()
        end

        -- Extract the first matching line number from the output (e.g., "32: \"react\":...")
        local line_number = result:match "^(%d+):"
        line_number = tonumber(line_number)

        if line_number then
          -- If we found a matching line, open package.json in the buffer
          vim.cmd("edit " .. plugin_file)

          -- Move the cursor to the matched line number at column 1
          vim.fn.cursor { line_number, 1 }
        else
          -- If no match was found, show an error message
          print("Plugin dependency not found: ", dep)
        end
      end,
    },
    ["ctrl-y"] = {
      fn = function(selected)
        if type(selected) == "table" then
          selected = table.concat(selected, " ")
        end
        vim.fn.setreg("+", selected)
        print("Path Copied" .. selected)
      end,
      exec_silent = true,
    },
    ["default"] = {
      fn = function(selected)
        if type(selected) == "table" then
          selected = table.concat(selected, " ")
        end
        -- Ensure the link is properly formatted with 'https://'
        local repo_url = "https://github.com/" .. selected

        -- Check if the operating system is Windows or non-Windows
        if package.config:sub(1, 1) == "\\" then
          -- For Windows, use 'start' or 'explorer' to open the URL
          os.execute("start " .. repo_url) -- You can also use "explorer" if needed
        else
          -- For non-Windows systems (Linux/macOS), use 'xdg-open' to open the URL
          os.execute("xdg-open " .. repo_url)
        end
      end,
      exec_silent = true,
    },
  }

  local file = io.open(plugin_file, "r")
  if not file then
    print("Failed to open file: " .. plugin_file)
    return
  end

  local file_content = file:read "*all"
  file:close()

  local links = {}

  -- Extract only the plugin names with '/' in them, ignoring other fields like 'build', 'event', etc.
  for link in string.gmatch(file_content, '"([^"\'%s]+/[^"\'%s]+)"') do
    table.insert(links, link)
  end

  if #links == 0 then
    return
  end

  fzf_lua.fzf_exec(links, opts)
end
