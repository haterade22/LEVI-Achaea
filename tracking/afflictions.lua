--- LEVI Affliction Tracking
-- Tracks afflictions on self and enemies
-- @module tracking.afflictions

local afflictions = {}

-- Affliction storage
local player_afflictions = {}
local enemy_afflictions = {}

--- Add an affliction to player
-- @param aff_name Name of the affliction
-- @param source Source of the affliction
function afflictions.add_player(aff_name, source)
  player_afflictions[aff_name] = {
    gained = os.time(),
    source = source or "unknown"
  }
  
  -- Raise event
  local events = require("core.events")
  events.raise("affliction_gained", {
    name = aff_name,
    source = source,
    target = "player"
  })
end

--- Remove an affliction from player
-- @param aff_name Name of the affliction
function afflictions.remove_player(aff_name)
  if player_afflictions[aff_name] then
    player_afflictions[aff_name] = nil
    
    -- Raise event
    local events = require("core.events")
    events.raise("affliction_cured", {
      name = aff_name,
      target = "player"
    })
  end
end

--- Check if player has an affliction
-- @param aff_name Name of the affliction
-- @return true if player has the affliction
function afflictions.has_player(aff_name)
  return player_afflictions[aff_name] ~= nil
end

--- Get all player afflictions
-- @return Table of player afflictions
function afflictions.get_player()
  return player_afflictions
end

--- Get count of player afflictions
-- @return Number of afflictions
function afflictions.count_player()
  local count = 0
  for _ in pairs(player_afflictions) do
    count = count + 1
  end
  return count
end

--- Add an affliction to enemy
-- @param enemy_name Name of the enemy
-- @param aff_name Name of the affliction
function afflictions.add_enemy(enemy_name, aff_name)
  if not enemy_afflictions[enemy_name] then
    enemy_afflictions[enemy_name] = {}
  end
  
  enemy_afflictions[enemy_name][aff_name] = {
    given = os.time(),
    confirmed = false
  }
  
  -- Raise event
  local events = require("core.events")
  events.raise("enemy_affliction_given", {
    enemy = enemy_name,
    name = aff_name
  })
end

--- Confirm an enemy affliction
-- @param enemy_name Name of the enemy
-- @param aff_name Name of the affliction
function afflictions.confirm_enemy(enemy_name, aff_name)
  if enemy_afflictions[enemy_name] and enemy_afflictions[enemy_name][aff_name] then
    enemy_afflictions[enemy_name][aff_name].confirmed = true
  end
end

--- Remove an enemy affliction
-- @param enemy_name Name of the enemy
-- @param aff_name Name of the affliction
function afflictions.remove_enemy(enemy_name, aff_name)
  if enemy_afflictions[enemy_name] then
    enemy_afflictions[enemy_name][aff_name] = nil
  end
end

--- Get enemy afflictions
-- @param enemy_name Name of the enemy
-- @return Table of enemy afflictions
function afflictions.get_enemy(enemy_name)
  return enemy_afflictions[enemy_name] or {}
end

--- Clear all afflictions
function afflictions.clear_all()
  player_afflictions = {}
  enemy_afflictions = {}
end

--- Initialize the afflictions module
function afflictions.init()
  afflictions.clear_all()
end

--- Reset the afflictions module
function afflictions.reset()
  afflictions.clear_all()
end

return afflictions
