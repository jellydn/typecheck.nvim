local log = require('typecheck.vlog')
local typescript_errors = require('typecheck.known_errors')

local M = {}
local separator = ' >>> '
--- Log info
---@vararg any
M.log_info = function(...)
  -- Only save log when debug is on
  if not _TYPECHECK_GLOBAL_CONFIG.debug then
    return
  end

  log.info(...)
end

--- Log error
---@vararg any
M.log_error = function(...)
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
M.create_cmd = function(cmd, func, opt)
  opt = vim.tbl_extend('force', { desc = 'typecheck.nvim ' .. cmd }, opt or {})
  vim.api.nvim_create_user_command(cmd, func, opt)
end

-- Function to remove ANSI color codes
---@param str string
---@return string
local function remove_ansi_codes(str)
  return str:gsub('\027%[[0-9;]*m', '')
end

-- Function to trim whitespace from a string
local function trim(s)
  return s:match('^%s*(.-)%s*$')
end

--- Parses the output of the TypeScript compiler (tsc) to identify and report errors.
--- This function analyzes both single-line and multi-line error messages.
--- It also considers known errors, which are skipped according to a predefined list.
--- Each error is simplified to its essence before being reported.
---@param data string The raw output string from the TypeScript compiler.
---@param type string The type of output, typically indicating the source of the message.
---@return table An array of tables containing parsed errors, with each table detailing a specific error.
M.parse_tsc_output = function(data, type)
  M.log_info('Parse tsc error message from ' .. type .. ':' .. data)
  local errors = {}
  local currentError = nil
  data = remove_ansi_codes(data)

  local last_line = nil
  for line in data:gmatch('[^\r\n]+') do
    line = trim(line)
    -- Match for single-line error (e.g., error TS2554: Expected 2 arguments, but got 3.)
    local file, lineno, colno, errorCode, errorMsg =
      line:match('^(.-)%((%d+),(%d+)%)%: error (TS%d+): (.+)')

    if not file then
      -- Match for first line of multi-line error
      -- E.g: Below is multi-line error
      -- [[
      -- error TS2834: Relative import paths need explicit file extensions in ECMAScript imports when '--moduleResolution' is 'node16' or 'nodenext'.
      -- Consider adding an extension to the import path.
      -- ]]
      file, lineno, colno, errorCode = line:match('^(.-)%:(%d+)%:(%d+)%s*%- error (TS%d+):')
      -- Get error message after error code
      errorMsg = line:match('error TS%d+: (.+)')
    end

    if file then
      if currentError then
        table.insert(errors, currentError)
      end

      if typescript_errors.known_errors[errorCode] then
        M.log_info('Error is known, simply skip it')
        table.insert(errors, {
          filename = file,
          lnum = tonumber(lineno),
          col = tonumber(colno),
          text = typescript_errors.known_errors[errorCode],
        })
      else
        -- Start of a new error
        currentError = {
          filename = file,
          lnum = tonumber(lineno),
          col = tonumber(colno),
          text = errorCode and ('error ' .. errorCode .. ': ' .. (errorMsg or '')) or '',
        }
      end
    end

    -- Detect the last error line which is often the root cause of the error
    if
      currentError
      and currentError.text -- Only add the last line if that is multi lines error
      and line ~= nil
      and not line:find('~+') -- Ignore lines with ~~~~
      and not line:find('.ts') -- Ignore lines with filename *.ts
      and not line:find('Found %d+ errors?') -- Ignore "Found x errors"
    then
      last_line = line
    end
  end

  if currentError then
    if _TYPECHECK_GLOBAL_CONFIG.only_show_first_error_message then
      currentError.text = M.simplify_error_message(currentError.text)
    elseif last_line then
      currentError.text = currentError.text .. separator .. last_line
    end

    table.insert(errors, currentError)
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

--- Simplify error message
--- Only keep the first and last line of the error message
---@param error_message string
---@return string
M.simplify_error_message = function(error_message)
  local lines = {}
  for line in string.gmatch(error_message, '([^>>>]+)') do
    line = line:gsub('^%s*(.-)%s*$', '%1') -- Trim whitespace

    -- Skip the line if it contains '~~~~~~'
    if not line:find('~+') then
      table.insert(lines, line)
    end
  end

  if #lines < 2 then
    M.log_info('Error message is not complex, return original message')
    return error_message -- Return the original message if it's not complex
  else
    return lines[1] .. separator .. lines[#lines]
  end
end

--- Find tsconfig.json nearest to current file
---@return string|nil
M.find_tsconfig_nearest = function()
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
      M.log_info('Found tsconfig.json at ' .. current_dir)
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
    M.log_info('Found tsconfig.json at ' .. root_dir)
    return root_dir .. '/tsconfig.json'
  end

  return nil
end

--- Find tsc binary
---@return string|nil
M.find_tsc_bin = function()
  local current_dir = vim.fn.expand('%:p:h')
  local root_dir = vim.fn.systemlist('git -C ' .. current_dir .. ' rev-parse --show-toplevel')[1]
  -- Check for tsc from current directory up to git root
  --
  M.log_info('Check for tsc from current directory up to git root')
  M.log_info('Current directory: ' .. current_dir)
  M.log_info('Git root: ' .. root_dir)
  local results = vim.fs.find({
    '/node_modules/.bin/tsc',
  }, { upward = true, path = current_dir, limit = math.huge })
  for _, path in ipairs(results) do
    M.log_info('Found tsc at ' .. path)
    if vim.fn.executable(path) == 1 then
      return path
    end
  end

  -- Check if yarn v1 is installed and has tsc
  local yarn_v1_tsc = vim.fn.systemlist('yarn bin tsc')
  M.log_info('Check for tsc with yarn v1: ' .. vim.inspect(yarn_v1_tsc))
  local tsc = vim.v.shell_error == 0 and yarn_v1_tsc ~= nil and contain_string(yarn_v1_tsc, 'tsc')
  -- Check tsc is executable
  if tsc and vim.fn.executable(tsc) == 1 then
    M.log_info('[yarn] - Found tsc at ' .. tsc)
    return tsc
  else
    M.log_error('[yarn] - tsc not found')
  end

  -- check if pnpm is installed and has tsc
  local pnpm_tsc = vim.fn.systemlist('pnpm bin')
  M.log_info('Check for tsc with pnpm: ' .. vim.inspect(pnpm_tsc))
  if
    vim.v.shell_error == 0
    and pnpm_tsc ~= nil
    and vim.fn.filereadable(pnpm_tsc[1] .. '/tsc') ~= 0
  then
    M.log_info('[pnpm] - Found tsc at ' .. pnpm_tsc[1] .. '/tsc')
    local tsc_bin = pnpm_tsc[1] .. '/tsc'
    if tsc_bin and vim.fn.executable(tsc_bin) == 1 then
      M.log_info('[pnpm] - Found tsc at ' .. tsc_bin)
      return tsc_bin
    else
      M.log_error('[pnpm] - tsc not found')
    end
  else
    M.log_error('[pnpm] - tsc not found')
  end

  -- TODO: Detect Bun if there is bun.lock and Bun is installed and has tsc

  -- TODO: Detect Deno if there is deno.lock and Deno is installed and has tsc

  return nil
end

--- Show error list in quickfix window or trouble if available
---@param mode 'open'|'close'
local function toggle_error_list(mode)
  if _TYPECHECK_GLOBAL_CONFIG.mode == 'trouble' then
    if mode == 'open' then
      require('trouble').open('quickfix')
    else
      require('trouble').close()
    end
  else
    if mode == 'open' then
      vim.cmd('copen')
    else
      vim.cmd('cclose')
    end
  end
end

--- Clear quickfix if the test is successful after running
M.clear_quickfix = function()
  -- Only clear typecheck list in quickfix if there is no error
  vim.fn.setqflist({}, ' ', {
    title = 'typecheck',
    items = {},
  })
  toggle_error_list('close')
end

M.send_to_quickfix = function(items)
  vim.fn.setqflist({}, ' ', {
    title = 'typecheck',
    items = items,
  })
  toggle_error_list('open')
end

return M
