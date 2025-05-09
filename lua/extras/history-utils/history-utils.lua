local M = {}

M.history_file = vim.fn.stdpath "cache" .. "/dirs_history.txt"

function M.read_history()
  local dirs = {}
  local seen = {}

  local file = io.open(M.history_file, "r")
  if file then
    for line in file:lines() do
      line = vim.fn.expand(line):gsub("/+$", "") -- Normalize
      if vim.fn.isdirectory(line) == 1 and not seen[line] then
        dirs[line] = true
        seen[line] = true
      end
    end
    file:close()
  end

  return dirs
end

function M.write_history(dirs)
  local file = io.open(M.history_file, "w")
  if file then
    for dir, _ in pairs(dirs) do
      file:write(dir .. "\n")
    end
    file:close()
  else
    print "⚠ Could not open history file for writing."
  end
end

function M.add_current_dir_to_history()
  local cwd = vim.fn.getcwd()
  if vim.fn.isdirectory(cwd) == 1 then
    _G.directories_history[cwd] = true
  end
end

vim.api.nvim_create_autocmd({ "VimLeavePre", "DirChanged" }, {
  callback = M.add_current_dir_to_history,
})

_G.directories_history = M.read_history()
-- 👇 Ensure any changes during session are written at exit
vim.api.nvim_create_autocmd("VimLeavePre", {
  callback = function()
    M.write_history(_G.directories_history)
  end,
})

return M
