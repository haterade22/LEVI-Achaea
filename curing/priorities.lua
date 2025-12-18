--- LEVI Curing Priorities
-- Defines curing priorities for afflictions
-- @module curing.priorities

local priorities = {}

-- Default priority levels
local PRIORITY_CRITICAL = 90
local PRIORITY_HIGH = 70
local PRIORITY_MEDIUM = 50
local PRIORITY_LOW = 30

-- Affliction priorities
local affliction_priorities = {
  -- Critical (life-threatening)
  anorexia = 95,
  asthma = 92,
  slickness = 90,
  
  -- High priority (major combat impact)
  paralysis = 85,
  impatience = 82,
  stupidity = 80,
  confusion = 80,
  
  -- Medium priority
  clumsiness = 60,
  nausea = 58,
  weariness = 55,
  sensitivity = 55,
  
  -- Low priority
  lovers = 30,
  peace = 30,
  recklessness = 35
}

--- Get priority for an affliction
-- @param aff_name Name of the affliction
-- @return Priority value (0-100)
function priorities.get(aff_name)
  return affliction_priorities[aff_name] or PRIORITY_MEDIUM
end

--- Set priority for an affliction
-- @param aff_name Name of the affliction
-- @param priority Priority value (0-100)
function priorities.set(aff_name, priority)
  affliction_priorities[aff_name] = priority
end

--- Get all priorities
-- @return Table of affliction priorities
function priorities.get_all()
  return affliction_priorities
end

--- Sort afflictions by priority
-- @param aff_list List of affliction names
-- @return Sorted list (highest priority first)
function priorities.sort(aff_list)
  table.sort(aff_list, function(a, b)
    return priorities.get(a) > priorities.get(b)
  end)
  return aff_list
end

--- Load priorities from configuration
-- @param config Configuration table
function priorities.load_from_config(config)
  if config and config.curing and config.curing.priorities then
    for aff_name, priority in pairs(config.curing.priorities) do
      affliction_priorities[aff_name] = priority
    end
  end
end

--- Initialize the priorities module
function priorities.init()
  -- Load from config if available
  local config = require("config.loader")
  if config and config.get then
    priorities.load_from_config(config.get())
  end
end

return priorities
