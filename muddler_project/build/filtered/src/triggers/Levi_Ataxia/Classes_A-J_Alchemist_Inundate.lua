local humour = matches[2]
if humour == "phlegmatic" then
	if not tAffs.phlegmatic then
		return
	else
		local affList = {}
		if not ataxia.vitals.class or ataxia.vitals.class == 0 then
			affList = {lethargy = 1, anorexia = 3, slickness = 5, weariness = 7}
		else
			affList = {lethargy = 1, anorexia = 5, slickness = 7}
		end
		local afflicted = {}
		for aff, count in pairs(affList) do
			if tAffs.phlegmatic > count then
				table.insert(afflicted, aff)
				tAffs[aff] = true
			end
		end
		raiseEvent("tar afflicted", afflicted)	
		checkTargetLocks()
	end
	tAffs.phlegmatic = nil
elseif humour == "sanguine" then
	selectString(line,1)
	fg("a_darkred")
	resetFormat()
	tAffs.sanguine = nil
elseif humour == "choleric" then
	selectString(line,1)
	fg("a_darkgreen")
	resetFormat()
	tAffs.choleric = nil
else
	selectString(line,1)
	fg("DeepSkyBlue")
	resetFormat()
	tAffs.melancholic = nil
end