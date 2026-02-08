send("g group ink from mill",false)
if ataxiaTemp.inkMaking then
	selectString(line,1)
	fg(ataxiaTemp.inkColour)
	deselect()
	
	if ataxiaTemp.inkAmount == 0 then
		ataxia_Echo("Finished creating all of the inks.")
		ataxiaTemp.inkColour = nil
		ataxiaTemp.inkAmount = nil
		ataxiaTemp.inkMaking = nil
	else
		ataxia_Echo(ataxiaTemp.inkAmount.." inks left to make.")
		inkmilling_createInks()
	end
end
