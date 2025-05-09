local utils = require "extras.utils"

_G.directories = _G.directories or {}
_G.directories_devices = {}
_G.directories_all = _G.directories_all or {}
_G.directories_history = _G.directories_history or {}

local windows_dirs = {
  { path = utils.home .. "\\vaults", alias = "Obsidian" },
  { path = utils.home .. "\\Documents", alias = "Documents" },
  { path = utils.home .. "\\Downloads", alias = "Downloads" },
  { path = utils.home .. "\\Pictures", alias = "Pictures" },
  { path = utils.home .. "\\E", alias = "E Hard Disk" },
  { path = utils.home .. "\\AppData\\Local\\nvim", alias = "nvim" },
  { path = utils.home .. "\\AppData\\Local\\nvim-data", alias = "nvim-data" },
  { path = utils.home .. "\\AppData\\Local\\Obsidian", alias = "Obsidian" },
  { path = utils.home .. "\\AppData\\Wezterm", alias = "Wezterm-" },
  { path = utils.home .. "\\", alias = "Home" },
  { path = utils.home .. "\\AppData\\Roaming\\alacritty", alias = "Alacritty" },
  { path = utils.home .. "\\AppData\\Roaming\\neovide", alias = "Neovide" },
  { path = utils.home .. "\\AppData\\lazygit", alias = "LazyGit" },
  { path = utils.home .. "\\.local\\share\\chezmoi", alias = "Chezmoi" },
}

local unix_dirs = {
  { path = utils.home .. "/Downloads", alias = "Downloads" },
  { path = utils.home .. "/Documents", alias = "Documents" },
  { path = utils.home .. "/Videos", alias = "Videos" },
  { path = utils.home .. "/Music", alias = "Music" },
  { path = utils.home .. "/Pictures", alias = "Pictures" },
  { path = utils.home .. "/.config/nvim", alias = "nvim" },
  { path = utils.home .. "/.local/share/nvim", alias = "nvim-data" },
  { path = utils.home .. "/.config/kitty", alias = "kitty" },
  { path = utils.home .. "/.config/neovide", alias = "neovide" },
  { path = utils.home .. "/.config/tmux", alias = "tmux" },
  { path = utils.home .. "/.config/alacritty", alias = "alacritty" },
  { path = utils.home .. "/.config/foot", alias = "foot" },
  { path = utils.home .. "/.config/hypr", alias = "hypr" },
  { path = utils.home .. "/.config/xplr", alias = "xplr" },
  { path = utils.home .. "/.config/helix", alias = "helix" },
  { path = utils.home .. "/.local/share/chezmoi", alias = "chezmoi" },
  { path = utils.home .. "/.local/share/fonts", alias = "fonts" },
  { path = utils.home .. "/nixos", alias = "nixos" },
  { path = utils.home .. "/", alias = "Home" },
}

if utils.is_windows() then
  _G.directories = vim.list_extend(_G.directories, windows_dirs)
else
  _G.directories = vim.list_extend(_G.directories, unix_dirs)
end
