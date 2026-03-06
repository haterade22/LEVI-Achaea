if isTargeted(matches[2]) then
	ataxiaTemp.curse = curseConvert(matches[3])
	
	if ataxiaTemp.curse ~= "breach" and ataxiaTemp.curse ~= "bleed" then
		tarAffed(ataxiaTemp.curse)
		if applyAffV3 then applyAffV3(ataxiaTemp.curse) end
    if partyrelay and not ataxia.afflictions.aeon then  send("pt "..target..": "..ataxiaTemp.curse) end
	else
		tAffs.curseward = false
		if removeAffV3 then removeAffV3("curseward") end
	end
	
	if haveAff("curseward") then erAff("curseward") end
	if ataxiaTemp.curse ~= "breach" and not ataxiaTemp.swiftcurse and not tzantzacurse and tAffs.haemophilia then
		send("Discern "..target)
	elseif beepBoop and beepBoop.enabled then
    send("Discern "..target)
	end
	targetIshere = true
	tAffs.bleed = tAffs.bleed or 0
   if not tAffs.haemophilia then
  tAffs.bleed = 0
  end
  if shaman.spiritisbound("teraile") then
    if tAffs.haemophilia then
    tAffs.bleed = tAffs.bleed + 40
    cecho(" <white>[<red>"..tAffs.bleed.."<white>]")
  end
  end
  ataxiaTemp.swiftcurse = false
	
	
end