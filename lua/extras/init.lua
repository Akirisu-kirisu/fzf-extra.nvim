-- extras/init.lua
local M = {}
local fzf_config  = require("extras.setup")
function M.setup()
  require("extras.functions.handlers")
  require("extras.keys")
  require("fzf-lua").setup(fzf_config)
end

return M
