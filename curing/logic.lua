--- LEVI Curing Logic
-- Main curing decision engine
-- @module curing.logic

local logic = {}

local enabled = true
local last_cure_time = 0
local cure_delay = 1 -- Minimum seconds between cures

--- Check if curing is enabled
-- @return Boolean
function logic.is_enabled()
  return enabled
end

--- Enable or disable curing
-- @param state Boolean
function logic.set_enabled(state)
  enabled = state
  
  local events = require("core.events")
  events.raise("curing_toggled", {enabled = enabled})
end

--- Determine which affliction to cure next
-- @return Affliction name or nil
function logic.get_next_cure()
  local afflictions = require("tracking.afflictions")
  local priorities = require("curing.priorities")
  local balances = require("tracking.balances")
  
  -- Don't cure if we don't have balance/eq
  if not balances.has_both() then
    return nil
  end
  
  -- Get player afflictions
  local player_affs = afflictions.get_player()
  
  -- Convert to sorted list
  local aff_list = {}
  for aff_name, _ in pairs(player_affs) do
    table.insert(aff_list, aff_name)
  end
  
  -- Sort by priority
  priorities.sort(aff_list)
  
  -- Return highest priority
  if #aff_list > 0 then
    return aff_list[1]
  end
  
  return nil
end

--- Execute a cure for an affliction
-- @param aff_name Name of the affliction to cure
-- @return Boolean indicating if cure was executed
function logic.cure(aff_name)
  if not enabled then
    return false
  end
  
  -- Check cure delay
  local current_time = os.time()
  if current_time - last_cure_time < cure_delay then
    return false
  end
  
  -- TODO: Implement actual cure execution
  -- This would send the appropriate command (eat herb, smoke pipe, etc.)
  
  last_cure_time = current_time
  
  local events = require("core.events")
  events.raise("cure_attempted", {affliction = aff_name})
  
  return true
end

--- Automatic curing tick (called periodically)
function logic.tick()
  if not enabled then
    return
  end
  
  local next_cure = logic.get_next_cure()
  if next_cure then
    logic.cure(next_cure)
  end
end

--- Initialize the curing logic module
function logic.init()
  enabled = true
  last_cure_time = 0
  
  -- Register for affliction events
  local events = require("core.events")
  events.register("affliction_gained", function(data)
    -- Automatically try to cure when we gain an affliction
    logic.tick()
  end, 10)
  
  events.register("balance_gained", function(data)
    -- Try to cure when we gain balance
    logic.tick()
  end, 5)
end

--- Reset the curing logic module
function logic.reset()
  last_cure_time = 0
end

return logic
