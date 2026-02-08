ataxiaBasher.shielded = false
ataxiaTemp.ignoreCrits = false
bashStats.attacks = bashStats.attacks + 1

if gmcp.Char.Status.class == "Apostate" then
battleRage_Timers.special = tempTimer(44, [[battleRage_Timers.special = nil]])
if partyrelay then
      send("pt Battlerage - Charmed given to " ..target)
    end
end

if gmcp.Char.Status.class == "Black Dragon" then
battleRage_Timers.special = tempTimer(35, [[battleRage_Timers.special = nil]])
if partyrelay then
      send("pt Battlerage - Fear given to " ..target)
    end
end

if gmcp.Char.Status.class == "Monk" then
battleRage_Timers.special = tempTimer(32, [[battleRage_Timers.special = nil]])
if partyrelay then
      send("pt Battlerage - Clumsiness given to " ..target)
    end
end

if gmcp.Char.Status.class == "Psion" then
battleRage_Timers.special = tempTimer(36, [[battleRage_Timers.special = nil]])
end

if gmcp.Char.Status.class == "Magi" then
battleRage_Timers.special = tempTimer(36, [[battleRage_Timers.special = nil]])
if partyrelay then
      send("pt Battlerage - Aeon given to " ..target)
    end
end
if gmcp.Char.Status.class == "Runewarden" then
battleRage_Timers.special = tempTimer(46, [[battleRage_Timers.special = nil]])
end

if gmcp.Char.Status.class == "Infernal" then
battleRage_Timers.special = tempTimer(38, [[battleRage_Timers.special = nil]])
end

if gmcp.Char.Status.class == "Blue Dragon" then
battleRage_Timers.special = tempTimer(24, [[battleRage_Timers.special = nil]])
if partyrelay then
      send("pt Battlerage - Clumsiness given to " ..target)
    end
end

if gmcp.Char.Status.class == "Blademaster" then
battleRage_Timers.special = tempTimer(34, [[battleRage_Timers.special = nil]])
  if not ataxia.afflictions.aeon then
    if partyrelay then
      send("pt Battlerage - Stun given to " ..target)
    end
  end
end
if gmcp.Char.Status.class == "Pariah" then
battleRage_Timers.special = tempTimer(39, [[battleRage_Timers.special = nil]])
  if not ataxia.afflictions.aeon then
    if partyrelay then
      send("pt Battlerage - Clumsiness given to " ..target)
    end
  end
end
if gmcp.Char.Status.class == "Serpent" then
battleRage_Timers.special = tempTimer(42, [[battleRage_Timers.special = nil]])
  if not ataxia.afflictions.aeon then
    if partyrelay then
      send("pt Battlerage - Amnesia given to " ..target)
    end
  end
end

if gmcp.Char.Status.class == "Bard" then
battleRage_Timers.special = tempTimer(42, [[battleRage_Timers.special = nil]])
  if not ataxia.afflictions.aeon then
    if partyrelay then
      send("pt Battlerage - Amnesia given to " ..target)
    end
  end
end


if type(target) == "number" and ataxiaBasher.enabled then
	bashConsoleEcho("battlerage", "Used Special battlerage")
	if not ataxiaBasher.manual then
		deleteFull()
	end
end

