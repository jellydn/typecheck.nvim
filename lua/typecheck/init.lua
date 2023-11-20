--- Default configuration for typecheck.nvim
local default_config = {
  debug = false,
  monorepo = false,
}
--- Global configuration for entire plugin, easy to access from anywhere
_TYPECHECK_GLOBAL_CONFIG = default_config
local M = {}

--- Setup typecheck.nvim
---@param options (table | nil)
--       - debug: (boolean | nil) default: false.
--       - mode: ('popup' | 'split') default: popup.
function M.setup(options)
  _TYPECHECK_GLOBAL_CONFIG =
    vim.tbl_extend('force', _TYPECHECK_GLOBAL_CONFIG, options or default_config)

  require('typecheck.main').setup()
end

return M
