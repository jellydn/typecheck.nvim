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

  it('should correctly parse complex tsc error output', function()
    local tsc_output =
      [[server.mts:34:26 - error TS2554: Expected 1 arguments, but got 0. >>>> 34   const contract = await getActiveSmartContract();]]

    local expected_output = {
      {
        filename = 'server.mts',
        lnum = 34,
        col = 26,
        text = 'error TS2554: Expected 1 arguments, but got 0. >>>> 34   const contract = await getActiveSmartContract();',
      },
    }

    local parsed_output = utils.parse_tsc_output(tsc_output, 'stdout')
    assert.are.same(expected_output, parsed_output)
  end)

  it('should simplify multi-line error message', function()
    local complex_error =
      "error TS2554: Expected 1 arguments, but got 0. >>>> 34   const contract = await getActiveSmartContract(); >>>> ~~~~~~~~~~~~~~~~~~~~~~~~ >>>> ../utils-server/db-orm/src/index.ts:280:46 >>>> 280 export async function getActiveSmartContract(contractKey: string) { >>>> ~~~~~~~~~~~~~~~~~~~ >>>> An argument for 'contractKey' was not provided."

    local simplified_tsc_error = utils.simplify_error_message(complex_error)
    assert.are.same(
      "error TS2554: Expected 1 arguments, but got 0. >>>> An argument for 'contractKey' was not provided.",
      simplified_tsc_error
    )
  end)

  it('should simplify single-line error message', function()
    local complex_error = "error TS1005: ')' expected."
    local simplified_tsc_error = utils.simplify_error_message(complex_error)
    assert.are.same("error TS1005: ')' expected.", simplified_tsc_error)
  end)
end)
