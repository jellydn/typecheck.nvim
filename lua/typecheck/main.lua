local utils = require('typecheck.utils')

local M = {}

local is_running = false
local is_monorepo = _TYPECHECK_GLOBAL_CONFIG.monorepo
function M.setup()
  -- Add new command for toggle monorepo mode
  utils.create_cmd('ToggleMonorepoMode', function()
    is_monorepo = not is_monorepo
    if is_monorepo then
      vim.notify('Typecheck monorepo mode enabled', vim.log.levels.INFO)
    else
      vim.notify('Typecheck monorepo mode disabled', vim.log.levels.INFO)
    end
  end, {})

  -- Add Typecheck command and send output to quickfix
  utils.create_cmd('Typecheck', function()
    if is_monorepo then
      vim.notify('Typechecking in monorepo', vim.log.levels.INFO)
    else
      vim.notify('Typechecking', vim.log.levels.INFO)
    end

    local tsc_path = utils.find_tsc_bin()
    if tsc_path == nil then
      vim.notify('tsc not found', vim.log.levels.ERROR)
      return
    end

    local tsconfig_path = utils.find_tsconfig_nearest()
    if tsconfig_path == nil then
      vim.notify('tsconfig.json not found', vim.log.levels.WARN)
    end

    if is_running then
      vim.notify('Typecheck already running', vim.log.levels.WARN)
      return
    end

    is_running = true
    local cmd = { tsc_path, '--noEmit' }

    if tsconfig_path ~= nil then
      cmd = { tsc_path, '--noEmit', '--project', tsconfig_path }
    else
      -- Only run for current file
      local current_file = vim.fn.expand('%:p')
      cmd = { tsc_path, '--noEmit', current_file }
    end

    -- If monorepo mode is enabled, use tsc --build instead
    if is_monorepo then
      if tsconfig_path ~= nil then
        local tsconfig_dir = vim.fn.fnamemodify(tsconfig_path, ':h')
        vim.cmd('cd ' .. tsconfig_dir)
        utils.log_info('Changed directory to ' .. tsconfig_dir)
      end
      --build, -b  Build one or more projects and their dependencies, if out of date
      cmd = { tsc_path, '--build', '--verbose' }
    end

    local output = {}
    local stderr = {}

    utils.log_info('Typecheck started with command: ' .. table.concat(cmd, ' '))
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
          vim.fn.setqflist({}, 'r', { title = 'Typecheck', items = output })
          vim.notify('Typecheck complete with ' .. total_errors .. ' errors', vim.log.levels.ERROR)
        else
          -- Send a hint to quickfix about check logs file or run :ToggleMonorepoMode then try again
          local log_file = string.format('%s/%s.log', vim.fn.stdpath('cache'), 'typecheck.nvim')
          vim.fn.setqflist({}, 'r', {
            title = 'Typecheck',
            items = {
              {
                filename = log_file,
                text = 'Typecheck failed, check typecheck.nvim.log for more details or run :ToggleMonorepoMode then try again.',
              },
            },
          })
        end
        vim.cmd('copen')
      else
        vim.notify('Typecheck passed', vim.log.levels.INFO)
      end

      vim.notify('Typecheck complete', vim.log.levels.INFO)
      is_running = false

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
    end
  end, {})
end

return M
