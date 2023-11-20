local typecheck = require('typecheck.init')
local utils = require('typecheck.utils')

describe('Typecheck.nvim - utils', function()
  it('should be able to load', function()
    assert.truthy(utils)
  end)

  it('should correctly parse tsc error output for TS1005', function()
    local tsc_output = "src/index.ts(5,21): error TS1005: ')' expected."
    local expected_output = {
      {
        filename = 'src/index.ts',
        lnum = 5,
        col = 21,
        text = "error TS1005: ')' expected.",
      },
    }

    local parsed_output = utils.parse_tsc_output(tsc_output, 'stdout')
    assert.are.same(expected_output, parsed_output)
  end)

  it('should correctly parse tsc error output for TS2345', function()
    local tsc_output =
      "src/index.ts(5,19): error TS2345: Argument of type 'number' is not assignable to parameter of type 'string'."
    local expected_output = {
      {
        filename = 'src/index.ts',
        lnum = 5,
        col = 19,
        text = "error TS2345: Argument of type 'number' is not assignable to parameter of type 'string'.",
      },
    }

    local parsed_output = utils.parse_tsc_output(tsc_output, 'stdout')
    assert.are.same(expected_output, parsed_output)
  end)
end)
