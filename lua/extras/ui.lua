local utils = require("extras.utils")

local M = {}

-- Function to pad a string to a specific width and alignment

function M.get_timestamp(dir_path)
  if utils.is_windows() then
    -- Handle Windows timestamp logic (empty for now)
    return ""
  else
    -- For non-Windows systems, use the 'stat' command to get the timestamp
    local handle = io.popen('stat --format="%y" "' .. dir_path .. '"')
    local timestamp = handle:read "*l"
    handle:close()
    return timestamp and timestamp:match "^(.-)%..*" or "" -- Strip milliseconds, or return empty if no timestamp
  end
end

M.max_alias_len, M.max_path_len = 0, 0
  -- Pad a string to the given width using left or right alignment
  -- Format a directory entry line
  -- local function format_directory_output(dir, timestamp, name_width, path_width, timestamp_width)
function M.format_directory_output(dir, name_width, parameter)
    local name = "  " .. dir.alias
    local path = "⟨" .. dir.path .. "⟩"
    local formatted_name = string.format("%-" .. name_width .. "s", name)
    local formatted_path = string.format("%s │ %s", "", path)

    if parameter then
        local formatted_parameter = string.format("%-" .. #dir.name + 2 .. "s", "(" .. dir.name .. ")") -- +2 for the parentheses        local formatGroup = string.format("%s │ %s │ %s", formatted_name .. formatted_path .. formatted_parameter)
        return string.format("%s │ %s │ %s", formatted_name .. formatted_path .. formatted_parameter)
    else
        return formatted_name .. formatted_path
    end
end
-- Function to format the directory details into a consistent output

function M.calculate_padding(list)
for _, link in ipairs(list) do
    M.max_alias_len = math.max(M.max_alias_len, #link.alias)
    M.max_path_len = math.max(M.max_path_len, #link.path)
  end
end

return M
