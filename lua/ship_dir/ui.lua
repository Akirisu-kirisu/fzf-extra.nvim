-- local utils = require("ship_dir.utils")

local M = {}

local function utils()
	return require("ship_dir.utils")
end
-- Function to pad a string to a specific width and alignment

function M.get_timestamp(dir_path)
	if utils().is_windows() then
		-- Handle Windows timestamp logic (empty for now)
		return ""
	else
		-- For non-Windows systems, use the 'stat' command to get the timestamp
		local handle = io.popen('stat --format="%y" "' .. dir_path .. '"')
		local timestamp = handle:read("*l")
		handle:close()
		return timestamp and timestamp:match("^(.-)%..*") or "" -- Strip milliseconds, or return empty if no timestamp
	end
end

M.max_alias_len, M.max_path_len = 0, 0
-- Pad a string to the given width using left or right alignment
-- Format a directory entry line
-- local function format_directory_output(dir, timestamp, name_width, path_width, timestamp_width)

local function pad_right(s, width)
  width = tonumber(width) or 0
  width = math.floor(width)
  if width <= 0 then
    return s
  end

  local len = #s
  if len >= width then
    return s
  end

  return s .. string.rep(" ", width - len)
end

function M.format_directory_output(dir, name_width, parameter)
  local name = "  " .. tostring(dir.alias or "")
  local path = "⟨" .. tostring(dir.path or "") .. "⟩"

  local formatted_name = pad_right(name, name_width)
  local formatted_path = " │ " .. path

  if parameter and dir.name then
    local param = "(" .. tostring(dir.name) .. ")"
    local formatted_parameter = pad_right(param, #param)
    return formatted_name .. formatted_path .. " │ " .. formatted_parameter
  end

  return formatted_name .. formatted_path
end
-- Function to format the directory details into a consistent output

---@param list { alias: string, path: string }[]
function M.calculate_padding(list)
  M.max_alias_len = 0
  M.max_path_len = 0

  for _, link in ipairs(list) do
    local alias_len = #(link.alias or "")
    local path_len  = #(link.path  or "")

    if alias_len > M.max_alias_len then
      M.max_alias_len = alias_len
    end

    if path_len > M.max_path_len then
      M.max_path_len = path_len
    end
  end

  -- harden
  M.max_alias_len = math.max(0, math.floor(M.max_alias_len or 0))
  M.max_path_len  = math.max(0, math.floor(M.max_path_len  or 0))

  -- enforce a *minimum* visual width
  local MIN_PATH_WIDTH = 24  -- tweak to taste
  if M.max_path_len < MIN_PATH_WIDTH then
    M.max_path_len = MIN_PATH_WIDTH
  end
end

return M
