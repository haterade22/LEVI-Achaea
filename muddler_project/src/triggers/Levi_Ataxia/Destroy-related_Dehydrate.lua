if isTargeted(matches[2]) then
		tarAffed("dehydrate")
		if dehydrateTimer then killTimer(dehydrateTimer) end
		dehydrateTimer = tempTimer(46, [[tAffs.burns = 0; tAffs.dehydrate = false]])
end