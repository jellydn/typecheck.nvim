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

--- Find if string contains substring
---@param str_list string[]
---@param keyword string
---@return string|nil
local function contain_string(str_list, keyword)
  for _, str in ipairs(str_list) do
    if str:find(keyword) then
      return str
    end
  end
  return nil
end

--- Find tsconfig.json nearest to current file
---@return string|nil
util.find_tsconfig_nearest = function()
  local current_file = vim.fn.expand('%:p')
  local current_dir = vim.fn.fnamemodify(current_file, ':h')
  local root_dir = vim.fn.systemlist('git -C ' .. current_dir .. ' rev-parse --show-toplevel')[1]

  if vim.v.shell_error ~= 0 then
    -- Git root not found, check if there is tsconfig.json in current directory
    local tsconfig = vim.fn.findfile('tsconfig.json', '.;')
    if tsconfig ~= '' then
      return tsconfig
    end
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
  util.log_info('Git root: ' .. root_dir)

  if vim.v.shell_error ~= 0 then
    -- Git root not found, file tsc binary in node_modules/.bin
    local node_modules_tsc_binary = vim.fn.findfile('node_modules/.bin/tsc', '.;')
    if node_modules_tsc_binary ~= '' then
      return node_modules_tsc_binary
    end
  end

  -- Check for tsc in node_modules/.bin
  local tsc_path = root_dir .. '/node_modules/.bin/tsc'
  util.log_info('Check for tsc in ' .. tsc_path)
  if vim.fn.filereadable(tsc_path) ~= 0 then
    util.log_info('Found tsc at ' .. tsc_path)
    return tsc_path
  end

  -- Check if yarn v1 is installed and has tsc
  local yarn_v1_tsc = vim.fn.systemlist('yarn bin tsc')
  util.log_info('Check for tsc with yarn v1: ' .. vim.inspect(yarn_v1_tsc))
  local tsc = vim.v.shell_error == 0 and yarn_v1_tsc ~= nil and contain_string(yarn_v1_tsc, 'tsc')
  if tsc then
    util.log_info('[yarn] - Found tsc at ' .. tsc)
    return tsc
  end

  -- check if pnpm is installed and has tsc
  local pnpm_tsc = vim.fn.systemlist('pnpm bin')
  util.log_info('Check for tsc with pnpm: ' .. vim.inspect(pnpm_tsc))
  if vim.v.shell_error == 0 and vim.fn.filereadable(pnpm_tsc[1] .. '/tsc') ~= 0 then
    util.log_info('[pnpm] - Found tsc at ' .. pnpm_tsc[1] .. '/tsc')
    return pnpm_tsc[1] .. '/tsc'
  end

  -- TODO: Detect Bun if there is bun.lock and Bun is installed and has tsc

  -- TODO: Detect Deno if there is deno.lock and Deno is installed and has tsc

  return nil
end

return util
