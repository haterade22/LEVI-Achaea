selectString(line,1)
	fg("white")
	bg("SeaGreen")
	setBold(true)
	resetFormat()
	ataxia_boxEcho(target:upper().."'S SHADOW HAS BEEN STOLEN", "purple")
  ataxia_boxEcho(target:upper().."'S SHADOW HAS BEEN STOLEN", "purple")
	tAffs.parasite = true
	if applyAffV3 then applyAffV3("parasite") end
	tAffs.healthleech = true
	if applyAffV3 then applyAffV3("healthleech") end
	tAffs.manaleech = true
	if applyAffV3 then applyAffV3("manaleech") end
  haveshadow = true
