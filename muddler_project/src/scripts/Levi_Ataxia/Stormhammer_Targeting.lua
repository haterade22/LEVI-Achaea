magi.storm = magi.storm or {}
magi.storm.targets = {}
magi.storm.starbursted = {}

-- Build target list: enemies from the same city as current target
function magi.storm.findTargets()
  local candidates = {}
  if not ataxia.playersHere or type(ataxia.playersHere) ~= "table" then return candidates end
  local targetCity = ataxiaNDB_getCitizenship(target)
  if not targetCity or targetCity == "" then return candidates end
  for _, person in pairs(ataxia.playersHere) do
    if ataxiaNDB_getCitizenship(person) == targetCity
       and person ~= gmcp.Char.Name
       and table.contains(ataxiaTemp.enemies, person) then
      table.insert(candidates, person)
    end
  end
  return candidates
end

-- Pick up to 3 targets
function magi.storm.selectTargets()
  magi.storm.targets = {}
  magi.storm.starbursted = {}
  local candidates = magi.storm.findTargets()
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
    local city = ataxiaNDB_getCitizenship(target) or "unknown"
    ataxia_boxEcho("No " .. city .. " enemies in room for stormhammer", "gold")
    return
  end
  local cmd = "cast stormhammer at " .. magi.storm.targets[1]
  if magi.storm.targets[2] then
    cmd = cmd .. " and " .. magi.storm.targets[2]
  end
  if magi.storm.targets[3] then
    cmd = cmd .. " and " .. magi.storm.targets[3]
  end
  ataxiaEcho("Stormhammer: " .. table.concat(magi.storm.targets, ", "))
  send("queue addclearfull freestand " .. cmd)
end
