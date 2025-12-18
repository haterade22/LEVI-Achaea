--- LEVI Balance Tracking
-- Tracks balance, equilibrium, and class-specific balances
-- @module tracking.balances

local balances = {}

-- Balance states
local balance_state = {
  balance = true,
  equilibrium = true,
  class_balance = {},
  last_lost = {},
  last_gained = {}
}

--- Set balance state
-- @param bal_type Type of balance (balance, equilibrium, or class name)
-- @param state Boolean state
function balances.set(bal_type, state)
  if bal_type == "balance" or bal_type == "equilibrium" then
    balance_state[bal_type] = state
  else
    balance_state.class_balance[bal_type] = state
  end
  
  -- Track timing
  if state then
    balance_state.last_gained[bal_type] = os.time()
  else
    balance_state.last_lost[bal_type] = os.time()
  end
  
  -- Raise event
  local events = require("core.events")
  local event_name = state and "balance_gained" or "balance_lost"
  events.raise(event_name, {type = bal_type})
end

--- Check if we have balance
-- @return Boolean
function balances.has_balance()
  return balance_state.balance == true
end

--- Check if we have equilibrium
-- @return Boolean
function balances.has_equilibrium()
  return balance_state.equilibrium == true
end

--- Check if we have both balance and equilibrium
-- @return Boolean
function balances.has_both()
  return balances.has_balance() and balances.has_equilibrium()
end

--- Check if we have a specific class balance
-- @param bal_name Name of the class balance
-- @return Boolean
function balances.has_class_balance(bal_name)
  return balance_state.class_balance[bal_name] == true
end

--- Get all balance states
-- @return Table of balance states
function balances.get_all()
  return balance_state
end

--- Get time since balance was lost
-- @param bal_type Type of balance
-- @return Seconds since lost, or nil if not lost
function balances.time_since_lost(bal_type)
  if balance_state.last_lost[bal_type] then
    return os.time() - balance_state.last_lost[bal_type]
  end
  return nil
end

--- Get time since balance was gained
-- @param bal_type Type of balance
-- @return Seconds since gained, or nil if not gained
function balances.time_since_gained(bal_type)
  if balance_state.last_gained[bal_type] then
    return os.time() - balance_state.last_gained[bal_type]
  end
  return nil
end

--- Lose balance
function balances.lose_balance()
  balances.set("balance", false)
end

--- Gain balance
function balances.gain_balance()
  balances.set("balance", true)
end

--- Lose equilibrium
function balances.lose_equilibrium()
  balances.set("equilibrium", false)
end

--- Gain equilibrium
function balances.gain_equilibrium()
  balances.set("equilibrium", true)
end

--- Initialize the balances module
function balances.init()
  balances.reset()
end

--- Reset the balances module
function balances.reset()
  balance_state = {
    balance = true,
    equilibrium = true,
    class_balance = {},
    last_lost = {},
    last_gained = {}
  }
end

return balances
