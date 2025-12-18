--- LEVI Offense Abilities
-- Defines offensive abilities and their properties
-- @module offense.abilities

local abilities = {}

-- Ability definitions
local ability_definitions = {
  -- Example Knight abilities
  dsl = {
    name = "doubleslash",
    balance_cost = "balance",
    balance_time = 2.5,
    class = "knight",
    args = {"venom1", "venom2"}
  },
  
  raze = {
    name = "raze",
    balance_cost = "balance",
    balance_time = 2.0,
    class = "knight",
    args = {}
  },
  
  -- Example Serpent abilities
  dstab = {
    name = "dstab",
    balance_cost = "balance",
    balance_time = 2.2,
    class = "serpent",
    args = {"venom"}
  },
  
  -- Add more abilities as needed
}

--- Get ability definition
-- @param ability_name Name of the ability
-- @return Ability definition table or nil
function abilities.get(ability_name)
  return ability_definitions[ability_name]
end

--- Register a new ability
-- @param ability_name Name of the ability
-- @param definition Ability definition table
function abilities.register(ability_name, definition)
  ability_definitions[ability_name] = definition
end

--- Check if an ability is available
-- @param ability_name Name of the ability
-- @return Boolean
function abilities.is_available(ability_name)
  local ability = abilities.get(ability_name)
  if not ability then
    return false
  end
  
  local balances = require("tracking.balances")
  
  -- Check balance cost
  if ability.balance_cost == "balance" then
    return balances.has_balance()
  elseif ability.balance_cost == "equilibrium" then
    return balances.has_equilibrium()
  elseif ability.balance_cost then
    return balances.has_class_balance(ability.balance_cost)
  end
  
  return true
end

--- Execute an ability
-- @param ability_name Name of the ability
-- @param args Arguments for the ability
-- @return Boolean indicating if execution was successful
function abilities.execute(ability_name, args)
  local ability = abilities.get(ability_name)
  if not ability then
    return false
  end
  
  if not abilities.is_available(ability_name) then
    return false
  end
  
  -- TODO: Implement actual ability execution
  -- This would send the appropriate command to the game
  
  local events = require("core.events")
  events.raise("offense_action", {
    ability = ability_name,
    args = args
  })
  
  return true
end

--- Get all abilities for a class
-- @param class_name Name of the class
-- @return Table of abilities
function abilities.get_for_class(class_name)
  local class_abilities = {}
  for name, ability in pairs(ability_definitions) do
    if ability.class == class_name then
      class_abilities[name] = ability
    end
  end
  return class_abilities
end

--- Initialize the abilities module
function abilities.init()
  -- Load additional abilities from config if needed
end

return abilities
