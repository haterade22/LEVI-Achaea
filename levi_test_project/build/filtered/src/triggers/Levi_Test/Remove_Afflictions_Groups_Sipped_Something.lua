if isTargeted(matches[2]) then
tdeliverance = false
  if passiveFailsafe then restorePassiveCure() end
	erAff("anorexia")
	if removeAffV3 then removeAffV3("anorexia") end

	if haveAff("voyria") and (pariah and not pariah.latency) then
		erAff("voyria")
		if removeAffV3 then removeAffV3("voyria") end
	end

  if haveAff("voyria") then
		erAff("voyria")
		if removeAffV3 then removeAffV3("voyria") end
	end

	if haveAff("nospeed") then
		tempTimer(3, [[ erAff("nospeed"); if removeAffV3 then removeAffV3("nospeed") end ]])
	end
  
  if ataxiaTemp.lastAssess then ataxiaTemp.lastAssess = ataxiaTemp.lastAssess + 21 end
  
	targetIshere = true
end