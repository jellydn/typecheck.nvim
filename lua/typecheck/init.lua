--- Default configuration for typecheck.nvim
local default_config = {
  debug = false,
  mode = 'trouble',
  only_show_first_error_message = true,
}
--- Global configuration for entire plugin, easy to access from anywhere
_TYPECHECK_GLOBAL_CONFIG = default_config
local M = {}

--- Setup typecheck.nvim
---@param options (table | nil)
--       - debug: (boolean | nil) default: false.
--       - mode: ('trouble' | 'quickfix') default: trouble.
--       - only_show_first_error_message: (boolean | nil) default: true.
function M.setup(options)
  _TYPECHECK_GLOBAL_CONFIG =
    vim.tbl_extend('force', _TYPECHECK_GLOBAL_CONFIG, options or default_config)

  require('typecheck.main').setup()
end

return M
