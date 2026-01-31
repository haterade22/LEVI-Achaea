if isTargeted(matches[2]) then
tdeliverance = false
  if passiveFailsafe then restorePassiveCure() end
	erAff("anorexia")
	
	if haveAff("voyria") and (pariah and not pariah.latency) then
		erAff("voyria")
	end
  
  if haveAff("voyria") then
		erAff("voyria")
	end
  
	if haveAff("nospeed") then
		tempTimer(3, [[ erAff("nospeed") ]])
	end
  
  if ataxiaTemp.lastAssess then ataxiaTemp.lastAssess = ataxiaTemp.lastAssess + 21 end
  
	targetIshere = true
end