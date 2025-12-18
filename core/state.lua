--- LEVI State Management
-- Manages global system state
-- @module core.state

local state = {}

-- System state
local system_state = {
  enabled = true,
  combat_active = false,
  target = nil,
  last_action = nil,
  last_action_time = 0
}

-- Player state
local player_state = {
  health = 0,
  max_health = 0,
  mana = 0,
  max_mana = 0,
  endurance = 0,
  max_endurance = 0,
  willpower = 0,
  max_willpower = 0,
  class = "unknown",
  level = 0
}

--- Get system state
-- @return System state table
function state.get_system()
  return system_state
end

--- Get player state
-- @return Player state table
function state.get_player()
  return player_state
end

--- Update system state
-- @param updates Table of state updates
function state.update_system(updates)
  for key, value in pairs(updates) do
    system_state[key] = value
  end
end

--- Update player state
-- @param updates Table of state updates
function state.update_player(updates)
  for key, value in pairs(updates) do
    player_state[key] = value
  end
end

--- Enable/disable the system
-- @param enabled Boolean
function state.set_enabled(enabled)
  system_state.enabled = enabled
end

--- Check if system is enabled
-- @return Boolean
function state.is_enabled()
  return system_state.enabled
end

--- Set combat active state
-- @param active Boolean
function state.set_combat_active(active)
  system_state.combat_active = active
end

--- Check if in combat
-- @return Boolean
function state.is_combat_active()
  return system_state.combat_active
end

--- Set current target
-- @param target_name Name of the target
function state.set_target(target_name)
  system_state.target = target_name
end

--- Get current target
-- @return Target name or nil
function state.get_target()
  return system_state.target
end

--- Initialize the state module
function state.init()
  -- Reset to defaults
  state.reset()
end

--- Reset state to defaults
function state.reset()
  system_state = {
    enabled = true,
    combat_active = false,
    target = nil,
    last_action = nil,
    last_action_time = 0
  }
  
  player_state = {
    health = 0,
    max_health = 0,
    mana = 0,
    max_mana = 0,
    endurance = 0,
    max_endurance = 0,
    willpower = 0,
    max_willpower = 0,
    class = "unknown",
    level = 0
  }
end

return state
