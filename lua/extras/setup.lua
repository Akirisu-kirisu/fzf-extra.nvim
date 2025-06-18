local actions = require "fzf-lua.actions"
local utils = require("fzf-lua").utils
local function hl_validate(hl)
  return not utils.is_hl_cleared(hl) and hl or nil
end

return {
  previewers = {
    builtin = {
      extensions = {
        -- force image preview to use viu or chafa
        ["png"] = { "viu", "-w", "40", "-h", "20" },
        ["jpg"] = { "viu", "-w", "40", "-h", "20" },
        ["jpeg"] = { "viu", "-w", "40", "-h", "20" },
        ["gif"] = { "chafa", "--symbols", "block", "--size", "40x20" },
      }
    }
  },
  { "default-title", "telescope" }, -- base profile
  desc = "match telescope default highlights|keybinds",
  files = {
    git_icons = false,
  },
  silent = true,
  finder = {
    silent = true,
  },
  winopts = {
    width = 1,
    height = 0.5,
    fullscreen = false,
    row = 1,
    preview = {
      hidden = "nohidden",
      -- vertical = kup:45%",
      -- horizontal = "right:50%",
      layout = "horizontal",
      -- flip_columns = 120,
      delay = 10,
      winopts = { number = false },
    },
  },
  fzf_opts = {
    ["--history"] = vim.fn.stdpath "data" .. "/fzf-lua-history",
    -- ["--info"] = "inline",
    -- ["--border"] = false,
    -- ["--preview-window"] = true,
    -- ["--no-scrollbar"] = false,
    ["--layout"] = "reverse", -- Choose layout: [default|reverse|reverse-list]
    -- ["--color"] = "bg+:-1", -- Set the fzf color options, with gray highlight line
    -- ["--highlight-line"] = true, -- fzf >= v0.53
    -- ["--marker"] = "+",
  },
  hls = {
    normal = hl_validate "TelescopeNormal",
    border = hl_validate "TelescopeBorder",
    title = hl_validate "TelescopePromptTitle",
    help_normal = hl_validate "TelescopeNormal",
    help_border = hl_validate "TelescopeBorder",
    preview_normal = hl_validate "TelescopeBorder",
    preview_border = hl_validate "TelescopeBorder",
    preview_title = hl_validate "TelescopePreviewTitle",
    -- builtin preview only
    cursor = hl_validate "Cursor",
    cursorline = hl_validate "TelescopeSelection",
    cursorlinenr = hl_validate "TelescopeSelection",
    search = hl_validate "IncSearch",
  },
  lsp = {
    jump_to_single_result = true,
    jump_to_single_result_action = actions.file_edit,
  },
  fzf_colors = {
    ["fg"] = { "fg", "TelescopeNormal" },
    ["bg"] = { "bg", "TelescopeNormal" },
    ["hl"] = { "fg", "TelescopeMatching" },
    ["fg+"] = { "fg", "TelescopeSelection" },
    ["bg+"] = { "bg", "TelescopeSelection" },
    ["hl+"] = { "fg", "TelescopeMatching" },
    ["info"] = { "fg", "TelescopeMultiSelection" },
    ["border"] = { "fg", "TelescopeBorder" },
    ["gutter"] = { "bg", "TelescopeNormal" },
    ["query"] = { "fg", "TelescopePromptNormal" },
    ["prompt"] = { "fg", "TelescopePromptPrefix" },
    ["pointer"] = { "fg", "TelescopeSelectionCaret" },
    ["marker"] = { "fg", "TelescopeSelectionCaret" },
    ["header"] = { "fg", "TelescopeTitle" },
  },
  extra_opts = {
    "--bind",
    "ctrl-f:preview-half-page-down,ctrl-b:preview-half-page-up",
  },

  keymap = {
    builtin = {
      false, -- do not inherit from defaults
      -- neovim `:tmap` mappings for the fzf win
      ["<F2>"] = "toggle-fullscreen",
      ["<F5>"] = "toggle-preview-ccw",
      ["<F6>"] = "toggle-preview-cw",
      ["<A-d>"] = "preview-page-down",
      ["<A-e>"] = "preview-page-up",
      ["<M-S-j>"] = "preview-down",
      ["<M-S-k>"] = "preview-up",
    },
    fzf = {
      ["alt-u"] = "beginning-of-line",
      ["alt-i"] = "beginning-of-line",
      ["alt-o"] = "end-of-line",
      -- ["alt-a"] = "toggle-all",
      ["ctrl-a"] = "toggle-all",
      -- ["alt-g"] = "last",
      -- ["alt-"] = "first",
      ["f3"] = "toggle-preview-wrap",
      ["f4"] = "toggle-preview",
    },
  },
  actions = {
    files = {
      ["alt-s"] = actions.file_split,
      ["alt-v"] = function(selected)
          vim.cmd("wincmd l") -- move to rightmost window
          vim.cmd("vsplit")   -- split right of it
          require("fzf-lua.actions").file_edit(selected[1])
      end,
      ["alt-e"] = actions.file_tabedit,
      ["enter"] = actions.file_edit_or_qf,
      ["alt-q"] = actions.file_sel_to_qf,
      ["alt-Q"] = actions.file_sel_to_ll,
    },
  },
}
