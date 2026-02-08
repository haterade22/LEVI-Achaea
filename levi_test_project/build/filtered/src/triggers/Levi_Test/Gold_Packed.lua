ataxiaTemp.goldinhand = nil
if type(target) == "number" and ataxiaBasher.enabled then

    if not ataxiaBasher.manual then
			deleteFull()
		end
end

if bashStats then
	bashStats.gainedGold = ( tonumber(gmcp.Char.Status.gold) - bashStats.loginGold )
end
