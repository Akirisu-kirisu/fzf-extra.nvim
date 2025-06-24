local actions = require("fzf-lua.actions")
local fzf_lua = require("fzf-lua")
local utils = require("extras.utils")
local ui = require("extras.ui")
local extra_actions = require("extras.actions")

_G.select_links = function(opts)
	utils.last_selected(select_links)
  opts = opts or {}
  opts.prompt = "Links> "

  opts.actions = {
      ["alt-m"] = {
			fn = function(selected)
				_G.select_main_menu_mfs()
			end,
			exec_silent = true,
		},
    ["default"] = {
      fn = function(selected)
        local selected_url = utils.selected_path(selected)
        -- Ensure the link is properly formatted with 'https://'
        local repo_url = "https://" .. selected_url
        --
        -- -- Check if the operating system is Windows or non-Windows
        if utils.is_windows() then
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

  -- Predefined array of popular links (with the base domain)
  local links = {
    {
      alias = "facebook.com",
      path = "Social media platform for connecting with friends and communities.",
    },
    {
      alias = "ui.shadcn.com",
      path = "UI components and design system for building modern web apps.",
    },
    {
      alias = "chatgpt.com",
      path = "Conversational AI by OpenAI for assistance, coding, and more.",
    },
    { alias = "youtube.com", path = "Video sharing and streaming platform." },
    {
      alias = "github.com",
      path = "Code hosting platform for version control and collaboration.",
    },
    { alias = "dotfyle.com", path = "Neovim plugin manager and explorer." },
    { alias = "outlook.com", path = "Web-based email service by Microsoft." },
    { alias = "comick.io", path = "Online comic and manga reading platform." },
    { alias = "mgeko.cc", path = "Another online manga/comic platform." },
    {
      alias = "asuracomic.net",
      path = "Site for reading translated manga and webtoons.",
    },
    { alias = "gmail.com", path = "Google's email service." },
    { alias = "google.com", path = "Search engine and tech services provider." },
    {
      alias = "reddit.com",
      path = "Community-based discussion and content sharing site.",
    },
    { alias = "neovim.io", path = "Official site for the Neovim text editor." },
    {
      alias = "fonts.google.com",
      path = "Google Fonts library for open-source typography.",
    },
    {
      alias = "search.nixos.org",
      path = "Search tool for NixOS packages and options.",
    },
    {
      alias = "storyset.com/",
      path = "Free animated illustrations and vector art for web and design projects.",
    },
    {
      alias = "msn.com/en-ph/weather",
      path = "Local weather forecasts and updates for the Philippines from MSN.",
    },
    {
      alias = "onehack.us/c/tutorials-methods/7",
      path = "Forum section with tutorials and methods for tech enthusiasts and hackers.",
    },
    {
      alias = "www.patterns.dev/posts/tree-shaking",
      path = "In-depth guide on JavaScript tree shaking for optimizing web bundlers.",
    },
    {
      alias = "github.com/leonardomso/33-js-concepts",
      path = "JavaScript best practices: factories and classes explained (Concept #14).",
    },
    {
      alias = "getintopc.com/",
      path = "Website offering free downloads of software and PC applications.",
    },
    {
      alias = "www.freesoftwarefiles.com/",
      path = "Directory of free software downloads for Windows and Mac.",
    },
    {
      alias = "downloadlyir.com",
      path = "Resource site for downloading premium software and tools for free.",
    },
    {
      alias = "http://localhost:5173/",
      path = "Vite Local Development",
    },
    {
      alias = "http://localhost:3000",
      path = "React Local Development",
    },
    {
      alias = "http://localhost:4173",
      path = "Vite Prod Development",
    },
    {
      alias = "http://localhost:8000",
      path = "Cloudflare Local Development",
    },
  }

  ui.calculate_padding(links)
  -- Prepare entries for FZF with proper alignment
  local fzf_entries = {}
  for _, link in ipairs(links) do
    local padded_name = string.format("%-" .. ui.max_alias_len .. "s", link.alias)
    local padded_desc = string.format("%-" .. ui.max_path_len .. "s", link.path)
    local url = string.format("%-" .. #link.alias + 2 .. "s", "⟨" .. link.alias .. "⟩") -- +2 for the parentheses

    table.insert(
      fzf_entries,
      string.format("%s │ %s │ %s", padded_name, padded_desc, url)
    )
  end
  -- Execute fzf with the predefined popular links
  fzf_lua.fzf_exec(fzf_entries, opts)
end
