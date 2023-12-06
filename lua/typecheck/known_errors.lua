local M = {
  -- NOTE: Let's add the friendly error messages here for helping the user to resolve the error.
  known_errors = {
    ['TS1238'] = 'error TS1238: Unable to resolve signature of class decorator when called as an expression.',
    ['TS1240'] = 'error TS1240: Unable to resolve signature of property decorator when called as an expression.',
    ['TS2769'] = 'error TS2769: No overload matches this call.',
    ['TS2349'] = 'error TS2349: This expression is not callable.',
  },
}

return M
