if isTargeted(matches[2]) then
		tarAffed("dehydrate")
		if applyAffV3 then applyAffV3("dehydrate") end
		if dehydrateTimer then killTimer(dehydrateTimer) end
		dehydrateTimer = tempTimer(46, [[tAffs.burns = 0; tAffs.dehydrate = false; if removeAffV3 then removeAffV3("dehydrate") end]])
end