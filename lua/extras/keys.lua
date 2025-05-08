local actions = require "fzf-lua.actions"
local fzf_lua = require("fzf-lua")
local utils = require("extras.utils")
local ui = require("extras.ui")
local extra_actions = require("extras.actions")
--
-- -- fzf-extras/lua/extras/keys.lua
-- require("extras.actions")
-- -- require("extras.utils")
-- -- require("extras.handlers")
-- -- Avoid recursive load unless this file is defining mappings
-- -- and not relying on itself
-- -- require("extras.keys") -- ⚠️ don't require self
--
--
-- -- define your keymaps here if needed
-- -- vim.keymap.set("n", "<leader>ff", require("fzf-lua").files, { desc = "FZF Files" })
--
--
-- utils.mapcombo("lua", handlers.select_directory_global_mfe, "mxe") -- visible output
-- utils.mapcombo("lua", handlers.select_directory_global_mfe, "mxe", "n", { silent = false }) -- visible output
-- Map our provider to a user command ':Directories'
vim.cmd [[command! -nargs=* Directories lua _G.select_directory_global_mfe()]]
-- Keybind
vim.keymap.set("n", "mxe", _G.select_directory_global_mfe)

vim.cmd [[command! -nargs=* Directories lua _G.select_main_menu_mfs()]]
-- Keybind
vim.keymap.set("n", "mxs", _G.select_main_menu_mfs)

vim.cmd [[command! -nargs=* Directories lua _G.main_menu_devices_mfd()]]
-- Keybind
vim.keymap.set("n", "mxd", _G.main_menu_devices_mfd)
--

-- print('test')
