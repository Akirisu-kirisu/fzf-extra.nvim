local utils = require "extras.utils"

_G.directories = _G.directories or {}
_G.directories_devices = {}
_G.directories_all = _G.directories_all or {}
_G.directories_history = _G.directories_history or {}
_G.directories_temp_back = _G.directories_temp_back or {}

_G.last_selected_fn_status = _G.last_selected_fn_status or {}
_G.last_selected_fn = _G.last_selected_fn or nil


local function add_existing_dirs(dirs)
  for _, dir in ipairs(dirs) do
    if utils.path_exists(dir.path) then
      table.insert(_G.directories, dir)
    end
  end
end

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
  { path = utils.home .. "/.config", alias = ".config" },
  { path = utils.home .. "/.local", alias = ".local" },
  { path = utils.home .. "/.local/bin", alias = "bin" },
  { path = utils.home .. "/.config/nvim", alias = "nvim" },
  { path = utils.home .. "/.local/share/nvim", alias = "nvim-data" },
  { path = utils.home .. "/.local/share/db_ui", alias = "db_ui" },
  { path = utils.home .. "/.config/kitty", alias = "kitty" },
  { path = utils.home .. "/.config/neovide", alias = "neovide" },
  { path = utils.home .. "/.config/tmux", alias = "tmux" },
  { path = utils.home .. "/.config/alacritty", alias = "alacritty" },
  { path = utils.home .. "/.config/foot", alias = "foot" },
  { path = utils.home .. "/.config/hypr", alias = "hypr" },
  { path = utils.home .. "/.config/xplr", alias = "xplr" },
  { path = utils.home .. "/.config/helix", alias = "helix" },
  { path = utils.home .. "/.config/dash", alias = "dash" },
  { path = utils.home .. "/.local/share/chezmoi", alias = "chezmoi" },
  { path = utils.home .. "/.local/share/fonts", alias = "fonts" },
  { path = utils.home .. "/nixos", alias = "nixos" },
  { path = utils.home .. "/", alias = "Home" },
  { path = "/etc", alias = "etc", sudo = true },
  { path = "/etc/sv", alias = "runit_sv", sudo = true },       -- for Void Linux runit services
  { path = "/var/service", alias = "runit_service", sudo = true }, -- symlinks to enable services
  { path = "/usr/local/bin", alias = "bin", sudo = true },   -- for custom scripts
  { path = "/etc/doas.conf", alias = "doas", sudo = true },
  { path = "/boot/loader/entries", alias = "boot_entries", sudo = true }, -- systemd-boot configs
  { path = "/etc/hostname", alias = "hostname", sudo = true },
  { path = "/etc/hosts", alias = "hosts", sudo = true },
  { path = "/etc/resolv.conf", alias = "resolv", sudo = true },
  { path = "/etc/network/interfaces", alias = "network", sudo = true }, -- or /etc/NetworkManager/system-connections/
}

_G.directories = _G.directories or {}

if utils.is_windows() then
  add_existing_dirs(windows_dirs)
else
  add_existing_dirs(unix_dirs)
end
