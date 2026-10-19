--[[mudlet
type: script
name: Stormhammer Targeting
hierarchy:
- Levi_Ataxia
- LEVI
- Levi  Scripts
- Leviticus
- Mage
attributes:
  isActive: 'yes'
  isFolder: 'no'
packageName: ''
]]--

magi.storm = magi.storm or {}
magi.storm.targets = {}
magi.storm.starbursted = {}
magi.storm.mode = magi.storm.mode or "city"  -- "city", "all", "priority"

----------------------------------------------------------------
-- Mode Management
----------------------------------------------------------------

function magi.storm.setMode(mode)
  local valid = {city = true, all = true, priority = true}
  if valid[mode] then
    magi.storm.mode = mode
    ataxiaEcho("Stormhammer mode set to: " .. mode)
  else
    ataxiaEcho("Invalid stormhammer mode: " .. tostring(mode) .. " (city/all/priority)")
  end
end

function magi.storm.getMode()
  return magi.storm.mode
end

----------------------------------------------------------------
-- Target Finders (per mode)
----------------------------------------------------------------

-- City mode: enemies from the same city as current target (original behavior)
local function findTargetsCity()
  local candidates = {}
  if not ataxia.playersHere or type(ataxia.playersHere) ~= "table" then return candidates end
  local targetCity = ataxiaNDB_getCitizenship(target)
  if not targetCity or targetCity == "" then return candidates end
  for _, person in pairs(ataxia.playersHere) do
    -- gmcp.Char.Name is an object {name, fullname}; compare against .name so self is
    -- actually excluded (a name string never equals the whole table -> guard was inert).
    if ataxiaNDB_getCitizenship(person) == targetCity
       and person ~= gmcp.Char.Name.name
       and table.contains(ataxiaTemp.enemies, person) then
      table.insert(candidates, person)
    end
  end
  return candidates
end

-- All mode: all enemies in room
local function findTargetsAll()
  local candidates = {}
  if not ataxia.playersHere or type(ataxia.playersHere) ~= "table" then return candidates end
  for _, person in pairs(ataxia.playersHere) do
    if person ~= gmcp.Char.Name.name
       and table.contains(ataxiaTemp.enemies, person) then
      table.insert(candidates, person)
    end
  end
  return candidates
end

-- Priority mode: use tprio.list ordering for enemies in room
local function findTargetsPriority()
  local candidates = {}
  if not tprio or not tprio.list then return findTargetsAll() end
  if not ataxia.playersHere or type(ataxia.playersHere) ~= "table" then return candidates end

  -- Build a lookup of enemies currently in room
  local inRoom = {}
  for _, person in pairs(ataxia.playersHere) do
    if person ~= gmcp.Char.Name.name
       and table.contains(ataxiaTemp.enemies, person) then
      inRoom[person] = true
    end
  end

  -- Walk tprio.list in order, pick those present
  for _, name in ipairs(tprio.list) do
    if inRoom[name] then
      table.insert(candidates, name)
      inRoom[name] = nil  -- avoid duplicates
    end
  end

  -- Append any remaining enemies not in tprio.list
  for person, _ in pairs(inRoom) do
    table.insert(candidates, person)
  end

  return candidates
end

-- Public findTargets dispatches to the active mode
function magi.storm.findTargets()
  local mode = magi.storm.mode
  if mode == "all" then
    return findTargetsAll()
  elseif mode == "priority" then
    return findTargetsPriority()
  else
    return findTargetsCity()
  end
end

-- Whether our target is a player gmcp lists in this room (v4.7.429). A hidden or departed player
-- is not listed, and a stormhammer at one is refused: Tabethys's log has "You cannot see that
-- being here." twice, each after a hand swap (kb/raw/logs/2026-10-19_tabethys_*).
function magi.storm.targetInRoom()
  if type(target) ~= "string" or target == "" then return false end
  if type(ataxia.playersHere) ~= "table" then return false end
  for _, person in pairs(ataxia.playersHere) do
    if type(person) == "string" and person:lower() == target:lower() then return true end
  end
  return false
end

-- Pick up to 3 targets, guaranteeing primary target is slot 1
function magi.storm.selectTargets()
  magi.storm.targets = {}
  magi.storm.starbursted = {}
  local candidates = magi.storm.findTargets()

  -- Ensure primary target is slot 1 if present and an enemy
  local placed = false
  if target and target ~= "" then
    for i, name in ipairs(candidates) do
      if name == target then
        if i ~= 1 then
          table.remove(candidates, i)
          table.insert(candidates, 1, target)
        end
        placed = true
        break
      end
    end
  end

  -- OUR TARGET IS ALWAYS SLOT 1 WHEN IT IS IN THE ROOM (v4.7.429). The finders take only enemied
  -- players (and, in city mode, of a known city), so a target we had not enemied, or one with no
  -- NDB city, was left out: with nobody else listed fire() echoed "No ... enemies" and sent
  -- nothing, and P4 / group mode returned nil, so the kill round was empty. With others listed, the
  -- stormhammer went at them and not at the target the round was for.
  if not placed and magi.storm.targetInRoom() then
    table.insert(candidates, 1, target)
  end

  for i = 1, math.min(3, #candidates) do
    table.insert(magi.storm.targets, candidates[i])
  end
end

-- Replace a dead target (no starburst) with next available
function magi.storm.replaceDead(deadName)
  if magi.storm.starbursted[deadName] then
    magi.storm.starbursted[deadName] = nil
    return
  end
  for i, name in ipairs(magi.storm.targets) do
    if name == deadName then
      local candidates = magi.storm.findTargets()
      for _, c in ipairs(candidates) do
        if not table.contains(magi.storm.targets, c) then
          magi.storm.targets[i] = c
          ataxiaEcho("Stormhammer: replaced " .. deadName .. " with " .. c)
          return
        end
      end
      table.remove(magi.storm.targets, i)
      ataxiaEcho("Stormhammer: " .. deadName .. " died, no replacement available")
      return
    end
  end
end

-- Send the stormhammer command
function magi.storm.fire()
  if #magi.storm.targets == 0 then
    magi.storm.selectTargets()
  end
  if #magi.storm.targets == 0 then
    local mode = magi.storm.mode
    local desc
    if mode == "city" then
      desc = (ataxiaNDB_getCitizenship(target) or "unknown") .. " city"
    elseif mode == "priority" then
      desc = "priority"
    else
      desc = "any"
    end
    ataxia_boxEcho("No " .. desc .. " enemies in room for stormhammer", "gold")
    return
  end
  local cmd = "cast stormhammer at " .. magi.storm.targets[1]
  if magi.storm.targets[2] then
    cmd = cmd .. " and " .. magi.storm.targets[2]
  end
  if magi.storm.targets[3] then
    cmd = cmd .. " and " .. magi.storm.targets[3]
  end
  -- The full round (stand, staff and shield, the cast, assess), as every other Magi round. The
  -- builder needs the offense (004); srr reaches this with or without it.
  if magi.offense and magi.offense.buildRound and type(target) == "string" and target ~= "" then
    send("queue addclearfull freestand " .. magi.offense.buildRound(cmd))
  else
    send("queue addclearfull freestand " .. cmd)
  end
  if magi.offense and magi.offense.castEcho and magi.offense.compactOn() then
    magi.offense.castEcho("Stormhammer", table.concat(magi.storm.targets, ", "))
  else
    ataxiaEcho("Stormhammer: " .. table.concat(magi.storm.targets, ", "))
  end
end
