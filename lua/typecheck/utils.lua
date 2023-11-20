local log = require('typecheck.vlog')

local util = {}

--- Log info
---@vararg any
util.log_info = function(...)
  -- Only save log when debug is on
  if not _TYPECHECK_GLOBAL_CONFIG.debug then
    return
  end

  log.info(...)
end

--- Log error
---@vararg any
util.log_error = function(...)
  -- Only save log when debug is on
  if not _TYPECHECK_GLOBAL_CONFIG.debug then
    return
  end

  log.error(...)
end

--- Create custom command
---@param cmd string The command name
---@param func function The function to execute
---@param opt table The options
util.create_cmd = function(cmd, func, opt)
  opt = vim.tbl_extend('force', { desc = 'typecheck.nvim ' .. cmd }, opt or {})
  vim.api.nvim_create_user_command(cmd, func, opt)
end

--- Parse tsc output
---@param data string
---@type string
---@return table
util.parse_tsc_output = function(data, type)
  util.log_info('Parse tsc error message from ' .. type .. ':' .. data)
  local errors = {}
  for line in data:gmatch('[^\r\n]+') do
    local file, lineno, colno, errorCode, errorMsg =
      line:match('^(.-)%((%d+),(%d+)%)%: error (TS%d+): (.+)')
    if file and lineno and colno and errorCode and errorMsg then
      table.insert(errors, {
        filename = file,
        lnum = tonumber(lineno),
        col = tonumber(colno),
        text = 'error ' .. errorCode .. ': ' .. errorMsg,
      })
    end
  end

  return errors
end

--- Find tsconfig.json nearest to current file
---@return string|nil
util.find_tsconfig_nearest = function()
  local current_file = vim.fn.expand('%:p')
  local current_dir = vim.fn.fnamemodify(current_file, ':h')
  local root_dir = vim.fn.systemlist('git -C ' .. current_dir .. ' rev-parse --show-toplevel')[1]

  if vim.v.shell_error ~= 0 then
    -- Git root not found
    util.log_info('Git root not found')
    return nil
  end

  while current_dir ~= root_dir do
    if vim.fn.filereadable(current_dir .. '/tsconfig.json') ~= 0 then
      util.log_info('Found tsconfig.json at ' .. current_dir)
      return current_dir .. '/tsconfig.json'
    end

    -- Move up one directory
    local parent_dir = vim.fn.fnamemodify(current_dir, ':h')
    if parent_dir == current_dir then
      -- No more parent directories, stop the loop
      break
    end
    current_dir = parent_dir
  end

  -- Check in the git root directory as well
  if vim.fn.filereadable(root_dir .. '/tsconfig.json') ~= 0 then
    util.log_info('Found tsconfig.json at ' .. root_dir)
    return root_dir .. '/tsconfig.json'
  end

  return nil
end

--- Find tsc binary
---@return string|nil
util.find_tsc_bin = function()
  local current_dir = vim.fn.expand('%:p:h')
  local root_dir = vim.fn.systemlist('git -C ' .. current_dir .. ' rev-parse --show-toplevel')[1]

  if vim.v.shell_error ~= 0 then
    util.log_info('Git root not found')
    return nil
  end

  -- Check for tsc in node_modules/.bin
  local tsc_path = root_dir .. '/node_modules/.bin/tsc'
  if vim.fn.filereadable(tsc_path) ~= 0 then
    util.log_info('Found tsc at ' .. tsc_path)
    return tsc_path
  end

  -- Check if yarn is installed and has tsc
  local yarn_tsc = vim.fn.systemlist('yarn global bin')
  if vim.v.shell_error == 0 and vim.fn.filereadable(yarn_tsc[1] .. '/tsc') ~= 0 then
    util.log_info('Found tsc at ' .. yarn_tsc[1] .. '/tsc')
    return yarn_tsc[1] .. '/tsc'
  end

  -- TODO: Detect bun if there is bun.lock and bun is istalled and has tsc

  -- TODO: Detect deno if there is deno.lock and deno is installed and has tsc

  return nil
end

return util
