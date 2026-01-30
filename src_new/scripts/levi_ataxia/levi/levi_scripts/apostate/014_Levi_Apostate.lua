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
  if not zgui.roomDenizenList then
    return false
  end
  if table.contains(zgui.roomDenizenList, "a frenzied bloodworm") then
    return true
  else
    return false
  end
end

function baalzadeen()
  if not zgui.roomDenizenList then
    return false
  end
  if table.contains(zgui.roomDenizenList, "a Baalzadeen") then
    return true
  else
    return false
  end
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
  if not zgui.roomDenizenList then
    return false
  end
  if table.contains(zgui.roomDenizenList, "a small winged daemonite") then
    return "daemonite"
  elseif table.contains(zgui.roomDenizenList, "a fiendish nightmare") then
    return "nightmare"
  elseif table.contains(zgui.roomDenizenList, "a razor fiend") then
    return "fiend"
  else
    return ""
  end
end

function daemonite()
  if not zgui.roomDenizenList then
    return false
  end
  for id, item in pairs(zgui.roomItemList) do
    if item.name:match("a small winged daemonite") then
      return true
    end
  end
  return false
end

function fiend()
  if not zgui.roomItemList then
    return false
  end
  for id, item in pairs(zgui.roomItemList) do
    if item.name:match("a razor fiend") then
      return true
    end
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
