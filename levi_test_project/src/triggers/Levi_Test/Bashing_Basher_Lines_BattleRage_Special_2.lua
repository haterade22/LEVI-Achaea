ataxiaBasher.shielded = false
ataxiaTemp.ignoreCrits = false
bashStats.attacks = bashStats.attacks + 1


if gmcp.Char.Status.class == "Shaman" then
battleRage_Timers.special2 = tempTimer(20, [[battleRage_Timers.special2 = nil]])
  if not ataxia.afflictions.aeon then
    if partyrelay then
      send("pt Battlerage - Recklessness given to " ..target)
    end
  end
end




if type(target) == "number" and ataxiaBasher.enabled then
	bashConsoleEcho("battlerage", "Used Special2 battlerage")
	if not ataxiaBasher.manual then
		deleteFull()
	end
end

