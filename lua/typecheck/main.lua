local utils = require('typecheck.utils')
local spinner = require('typecheck.spinner')

local M = {}

local is_running = false

local function run_typecheck(cmd)
  local output = {}
  local stderr = {}
  local handle
  local function on_exit(code)
    local is_success = code == 0
    if not is_success then
      -- Merge stderr into output
      for _, err in ipairs(stderr) do
        table.insert(output, err)
      end
    end
    local total_errors = #output

    if not is_success then
      if total_errors > 0 then
        utils.send_to_quickfix(output)
        vim.notify('Typecheck complete with ' .. total_errors .. ' errors', vim.log.levels.ERROR)
      end
    else
      utils.clear_quickfix()
      vim.notify('Typecheck passed', vim.log.levels.INFO)
    end

    is_running = false
    spinner.hide_spinner()

    if handle then
      handle:close()
    end
  end

  local stdout = vim.loop.new_pipe(false)
  local stderr_pipe = vim.loop.new_pipe(false)

  handle = vim.loop.spawn(cmd[1], {
    args = { unpack(cmd, 2) },
    stdio = { nil, stdout, stderr_pipe },
  }, vim.schedule_wrap(on_exit))

  if stdout == nil then
    vim.notify('Failed to open stdout pipe', vim.log.levels.ERROR)
    return
  end

  if stderr_pipe == nil then
    vim.notify('Failed to open stderr pipe', vim.log.levels.ERROR)
    return
  end

  vim.loop.read_start(stdout, function(err, data)
    assert(not err, err)
    if data then
      utils.log_info('Read data from stdout')
      local parsed_errors = utils.parse_tsc_output(data, 'stdout')
      utils.log_info('Parsed errors: ' .. vim.inspect(parsed_errors))
      for _, error_line in ipairs(parsed_errors) do
        table.insert(output, error_line)
      end
    end
  end)

  vim.loop.read_start(stderr_pipe, function(err, data)
    assert(not err, err)
    if data then
      utils.log_info('Read data from stderr_pipe')
      local parsed_errors = utils.parse_tsc_output(data, 'stderr_pipe')
      utils.log_info('Parsed errors: ' .. vim.inspect(parsed_errors))
      for _, error_line in ipairs(parsed_errors) do
        table.insert(stderr, error_line)
      end
    end
  end)

  if not handle then
    vim.notify('Failed to start typecheck', vim.log.levels.ERROR)
    is_running = false
    spinner.hide_spinner()
  end
end
function M.setup()
  -- Add Typecheck command and send output to quickfix
  utils.create_cmd('Typecheck', function()
    if is_running then
      vim.notify('Typecheck already running', vim.log.levels.WARN)
      return
    end

    spinner.show_spinner()
    vim.notify('Typechecking', vim.log.levels.INFO)

    local tsc_path = utils.find_tsc_bin()
    if tsc_path == nil then
      vim.notify('tsc not found', vim.log.levels.ERROR)
      return
    end

    local tsconfig_path = utils.find_tsconfig_nearest()
    if tsconfig_path == nil then
      vim.notify('tsconfig.json not found', vim.log.levels.WARN)
    end

    local cmd = {}
    if tsconfig_path ~= nil then
      local tsconfig_dir = vim.fn.fnamemodify(tsconfig_path, ':h')
      utils.log_info('Change directory to ' .. tsconfig_dir)
      vim.cmd('cd ' .. tsconfig_dir)
      cmd = { tsc_path, '--noEmit' }
    else
      -- Only run for current file
      local current_file = vim.fn.expand('%:p')
      cmd = { tsc_path, '--noEmit', current_file }
    end

    utils.log_info('Typecheck started with command: ' .. table.concat(cmd, ' '))

    run_typecheck(cmd)
  end, {})
end

return M
