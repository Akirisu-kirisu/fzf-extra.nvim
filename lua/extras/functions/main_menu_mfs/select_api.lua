local fzf_lua = require("fzf-lua")
local utils = require("extras.utils")
_G.select_api = function(opts)

local utils = require("extras.utils")
	utils.last_selected(select_api)
	opts = opts or {}
	opts.prompt = "API> "

	opts.actions = {
        ["alt-m"] = {
			fn = function(selected)
				_G.select_main_menu_mfs()
			end,
			exec_silent = true,
		},
		["ctrl-y"] = {
			fn = function(selected)
				-- Change the print statement to use vim.inspect to safely print the table
				print("DEBUGPRINT[1]: fzf.lua:858: selected=" .. vim.inspect(selected))
				vim.fn.setreg("+", selected)
				print("Path Copied: " .. vim.inspect(selected)) -- Use vim.inspect to print the table as a string
			end,
			exec_silent = true,
		},
		["default"] = {
			fn = function(selected)
				vim.fn.setreg("+", selected)
				print("Path Copied: " .. vim.inspect(selected)) -- Use vim.inspect to print the table as a string
			end,
			exec_silent = true,
		},
	}

	-- Predefined array of popular links (with the base domain)
	local popular_links = {
		"https://jsonplaceholder.typicode.com/users",
		"https://jsonplaceholder.typicode.com/comments",
		"https://api.thedogapi.com/v1/images/search",
		"https://api.thecatapi.com/v1/images/search",
		"https://api.coingecko.com/api/v3/simple/price?ids=bitcoin&vs_currencies=usd",
		"https://restcountries.com/v3.1/all",
		"https://v2.jokeapi.dev/joke/Programming",
		"https://opentdb.com/api.php?amount=10&type=multiple", -- Changed to the actual URL for Neovim
		"https://gateway.marvel.com/v1/public/characters?apikey={API_KEY}", -- Changed to the actual URL for Neovim
		"https://pokeapi.co/api/v2/pokemon/{id_or_name}", -- Fixed typo from "reedit.com"
		"https://newsapi.org/v2/top-headlines?country=us&apiKey={API_KEY}", -- Changed to the actual URL for Neovim
		"https://restcountries.com/v3.1/name/{country_name}",
		"https://api.openweathermap.org/data/2.5/weather?q={city name}&appid={API_KEY}",
		"https://api.ipgeolocation.io/ipgeo?apiKey={API_KEY}&ip={ip_address}",
	}

	-- Execute fzf with the predefined popular links
	fzf_lua.fzf_exec(popular_links, opts)
end
