local M = {}

function M.path_exists(path)
  return vim.fn.isdirectory(path) == 1
end
function M.get_user_home()
	return os.getenv("HOME") or os.getenv("USERPROFILE") -- This will work for both Unix and Windows
end

M.home = M.get_user_home() or "unknown"

M.directories = M.directories or {}
M.directories_devices = {}
M.directories_all = M.directories_all or {}
M.directories_history = M.directories_history or {}
M.directories_temp_back = M.directories_temp_back or {}

M.last_selected_fn_status = M.last_selected_fn_status or {}
M.last_selected_fn = M.last_selected_fn or nil


local function add_existing_dirs(dirs)
  for _, dir in ipairs(dirs) do
    if M.path_exists(dir.path) then
      table.insert(M.directories, dir)
    end
  end
end

local windows_dirs = {
  { path = M.home .. "\\vaults", alias = "Obsidian" },
  { path = M.home .. "\\Documents", alias = "Documents" },
  { path = M.home .. "\\Downloads", alias = "Downloads" },
  { path = M.home .. "\\Pictures", alias = "Pictures" },
  { path = M.home .. "\\E", alias = "E Hard Disk" },
  { path = M.home .. "\\AppData\\Local\\nvim", alias = "nvim" },
  { path = M.home .. "\\AppData\\Local\\nvim-data", alias = "nvim-data" },
  { path = M.home .. "\\AppData\\Local\\Obsidian", alias = "Obsidian" },
  { path = M.home .. "\\AppData\\Wezterm", alias = "Wezterm-" },
  { path = M.home .. "\\", alias = "Home" },
  { path = M.home .. "\\AppData\\Roaming\\alacritty", alias = "Alacritty" },
  { path = M.home .. "\\AppData\\Roaming\\neovide", alias = "Neovide" },
  { path = M.home .. "\\AppData\\lazygit", alias = "LazyGit" },
  { path = M.home .. "\\.local\\share\\chezmoi", alias = "Chezmoi" },
}

local unix_dirs = {
  { path = M.home .. "/Downloads", alias = "Downloads" },
  { path = M.home .. "/Documents", alias = "Documents" },
  { path = M.home .. "/Videos", alias = "Videos" },
  { path = M.home .. "/Music", alias = "Music" },
  { path = M.home .. "/Pictures", alias = "Pictures" },
  { path = M.home .. "/secrets", alias = "secrets" },
  { path = M.home .. "/.config", alias = ".config" },
  { path = M.home .. "/.local", alias = ".local" },
  { path = M.home .. "/.local/bin", alias = "bin" },
  { path = M.home .. "/.config/nvim", alias = "nvim" },
  { path = M.home .. "/.local/share/nvim", alias = "nvim-data" },
  { path = M.home .. "/.local/share/db_ui", alias = "db_ui" },
  { path = M.home .. "/.config/kitty", alias = "kitty" },
  { path = M.home .. "/.config/neovide", alias = "neovide" },
  { path = M.home .. "/.config/tmux", alias = "tmux" },
  { path = M.home .. "/.config/alacritty", alias = "alacritty" },
  { path = M.home .. "/.config/foot", alias = "foot" },
  { path = M.home .. "/.config/hypr", alias = "hypr" },
  { path = M.home .. "/.config/xplr", alias = "xplr" },
  { path = M.home .. "/.config/helix", alias = "helix" },
  { path = M.home .. "/.config/dash", alias = "dash" },
  { path = M.home .. "/.local/share/chezmoi", alias = "chezmoi" },
  { path = M.home .. "/.local/share/fonts", alias = "fonts" },
  { path = M.home .. "/nixos", alias = "nixos" },
  { path = M.home .. "/", alias = "Home" },
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

M.directories = M.directories or {}

function M.is_windows()
	return package.config:sub(1, 1) == "\\"
end

if M.is_windows() then
  add_existing_dirs(windows_dirs)
else
  add_existing_dirs(unix_dirs)
end
return M
