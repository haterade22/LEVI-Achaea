--[[mudlet
type: script
name: Levi Apostate
hierarchy:
- Levi_Ataxia
- LEVI
- Levi  Scripts
- Leviticus
- APOSTATE
attributes:
  isActive: 'yes'
  isFolder: 'no'
packageName: ''
]]--

--[[mudlet
type: script
name: Levi Apostate
hierarchy:
- Levi_Ataxia
- LEVI
- Levi  Scripts
- Leviticus
- APOSTATE
attributes:
  isActive: 'yes'
  isFolder: 'no'
packageName: ''
]]--

--------------------------------------------------------------------------------
-- BACKWARD COMPATIBILITY WRAPPERS
-- Old function names route to the new CC_Apostate system (015_CC_Apostate.lua)
--------------------------------------------------------------------------------

function leviclumsapo()
  apostate.state.mode = "lock"
  apostate.dispatch()
end

function leviweariapo()
  apostate.state.mode = "lock"
  apostate.dispatch()
end

function levisleepapo()
  apostate.state.mode = "sleep"
  apostate.dispatch()
end

function apostate_lock()
  apostate.state.mode = "lock"
  apostate.dispatch()
end

function apostate_lockattack()
  apostate.dispatch()
end

function apostate_lockImpale()
  apostate.state.mode = "lock"
  apostate.dispatch()
end

function apostate_sleepattack()
  apostate.state.mode = "sleep"
  apostate.dispatch()
end

function apostate_clumsy()
  apostate.state.mode = "lock"
  apostate.dispatch()
end

function apostate_vivisect()
  apostate.state.mode = "vivisect"
  apostate.dispatch()
end

function apostate_weari()
  apostate.state.mode = "lock"
  apostate.dispatch()
end

function apostate_mental()
  apostate.state.mode = "lock"
  apostate.dispatch()
end

function apostate_kelp()
  apostate.state.mode = "lock"
  apostate.dispatch()
end

function apostate_group()
  apostate.state.mode = "group"
  apostate.dispatch()
end

function apostate_clumsyillusion()
  apostate.state.mode = "lock"
  apostate.dispatch()
end

-- Legacy corruptDmg wrapper
function corruptDmg()
  return apostate.corruptDmg()
end

function corruptKill()
  if ataxiaTemp and ataxiaTemp.lastAssess and ataxiaTemp.lastAssess <= apostate.corruptDmg() then
    apostate.state.mode = "corrupt"
    apostate.dispatch()
  end
end

function cathCorrupt()
  if pm and pm - apostate.corruptDmg() <= 20 then
    apostate.state.mode = "corrupt"
    apostate.dispatch()
  end
end

--------------------------------------------------------------------------------
-- DAEMON UTILITY FUNCTIONS (kept as-is, used by CC_Apostate and triggers)
--------------------------------------------------------------------------------

function bloodPact()
  if not apo.pentagram() then
    if bloodTimer then
      if not dsum then
        addToCommand("summon daegger")
      end
      addToCommand(
        "wield daegger shield;demon bloodpact &tar for " ..
        pentagramEnt ..
        "/order loyals kill &tar"
      )
    end
  elseif apo.demon() ~= pentagramEnt then
    if not dsum then
      addToCommand("summon daegger")
    end
    addToCommand("wield daegger shield;dispel pentagram;summon " .. pentagramEnt)
  end
end

function bloodworm()
  if not ataxia or not ataxia.denizensHere then return false end
  for _, name in pairs(ataxia.denizensHere) do
    if name:lower():find("bloodworm") then return true end
  end
  return false
end

function baalzadeen()
  if ataxia and ataxia.denizensHere then
    for _, name in pairs(ataxia.denizensHere) do
      if name:lower():find("baalzadeen") then
        return true
      end
    end
  end
  return false
end

function apopentagram()
  if not zgui.roomItemList then
    return false
  end
  if table.contains(zgui.roomItemList, "a floating silver pentagram") then
    return true
  else
    return false
  end
end

function demon()
  if not ataxia or not ataxia.denizensHere then return false end
  for _, name in pairs(ataxia.denizensHere) do
    local ln = name:lower()
    if ln:find("daemonite") then return "daemonite"
    elseif ln:find("nightmare") then return "nightmare"
    elseif ln:find("razor fiend") then return "fiend"
    end
  end
  return ""
end

function daemonite()
  if not ataxia or not ataxia.denizensHere then return false end
  for _, name in pairs(ataxia.denizensHere) do
    if name:lower():find("daemonite") then return true end
  end
  return false
end

function fiend()
  if not ataxia or not ataxia.denizensHere then return false end
  for _, name in pairs(ataxia.denizensHere) do
    if name:lower():find("razor fiend") then return true end
  end
  return false
end

--------------------------------------------------------------------------------
-- NIGHTMARE TRACKING (timer-based affliction prediction)
--------------------------------------------------------------------------------

function nightmare()
  if gmcp.Char.Status.class == "Apostate" and demon() == "nightmare" then
    maretick = tempTimer(6.5, [[maretick = false; maretick = true]])
    nightmareaff = tempTimer(8.5, [[nightmareaff = false; nightmareaff = true]])

    if nightmareaff and tAffs.dementia and tAffs.hypersomnia then
      tarAffed("hellsight")
    elseif nightmareaff and tAffs.hypersomnia and not tAffs.dementia then
      tarAffed("dementia")
    end
  end
end
