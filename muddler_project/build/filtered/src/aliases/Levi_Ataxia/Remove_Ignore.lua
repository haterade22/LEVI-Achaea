if ataxiaBasher.mobIgnore then
	ataxiaEcho("Displaying currently ignored mobs. Click to remove them.")
	for i,v in pairs(ataxiaBasher.mobIgnore) do
		cecho("\n  <red>- ")
		fg("white")
		echoLink(v, [[ataxiaBasher_unignoremob("]]..v..[[")]], "Remove "..v.." from ignore list.", true)
		cecho(" <red>-")
	end
	send(" ")
else
	ataxiaEcho("Area not currently populated.")
end