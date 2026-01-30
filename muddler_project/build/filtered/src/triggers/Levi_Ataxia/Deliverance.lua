if isTargeted(matches[2]) then
	ataxia_boxEcho("TARGET IS USING DELIVERANCE", "NavajoWhite:firebrick")
	send("clearqueue all",false)
	
	if beepBoop and beepBoop.enabled then
		beepBoop.souls = beepBoop.souls or {}
		table.insert(beepBoop.souls, target)
		tempTimer(25, [[ beepBoop_removeSoul("]]..target..[[") ]])
		send("ql",false)
		expandAlias("bbnt")
	end	
end
