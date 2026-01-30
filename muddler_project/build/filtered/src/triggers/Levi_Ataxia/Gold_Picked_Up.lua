ataxiaTemp.goldInRoom = false
if type(target) == "number" and ataxiaBasher.enabled then
	bashConsoleEchom("$$$", "Picked up "..matches[2].." gold.", "goldenrod", "yellow")
    if not ataxiaBasher.manual then
			deleteFull()
		end
end

if bashStats then
	bashStats.gainedGold = ( tonumber(gmcp.Char.Status.gold) - bashStats.loginGold )
end
