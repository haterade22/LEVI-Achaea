-- unnamed > For Levi > Levi_062424 > mudlet-mapper_24 > Mudlet Mapper > Game-specific > Achaea > mmp.achaeaGaiaWhirlpoolReset

function mmp.achaeaGaiaWhirlpoolReset(event, game)
	if game == "Achaea" then
		mmp.whirlString = 'script: send("enter whirlpool") if tempWhirlTrigger then killTrigger(tempWhirlTrigger) tempWhirlTrigger = nil end if tempWhirlTimer then killTimer(killWhirlTimer) tempWhirlTimer = nil end tempWhirlTrigger = tempTrigger("What do you wish to enter?", [[if tempWhirlTimer then killTimer(tempWhirlTimer) tempWhirlTimer = nil end mmp.echo("Whirlpool not found here. Trying another room.") local x = {45817, 45780, 45903, 45868, 46254, 45866} if tempWhirlTrigger then killTrigger(tempWhirlTrigger) tempWhirlTrigger = nil end clearSpecialExits(]]..mmp.currentroom..[[) local y = table.index_of(x, ]]..mmp.currentroom..[[) + 1 if y > #x then y = 1 end addSpecialExit(x[y], 793, mmp.whirlString) mmp.clearpathcache() mmp.gotoRoom(mmp.speedWalkPath[#mmp.speedWalkPath]) mmp.echo("Moved whirlpool to "..x[y]..".")]]) tempWhirlTimer = tempTimer(1, [[if tempWhirlTrigger then killTrigger(tempWhirlTrigger) tempWhirlTrigger = nil end if tempWhirlTimer then killTimer(tempWhirlTimer) tempWhirlTimer = nil end]])'
		local x = {45817, 45780, 45903, 45868, 46254, 45866}
		for i, v in ipairs(x) do clearSpecialExits(v) end
		addSpecialExit(45868, 793, mmp.whirlString)
	end
end