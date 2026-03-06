local name = matches[2]
local voyriaBlock = ((pariah and pariah.latency) and true or false)

if isTargeted(matches[2]) then
  if haveAff("voyria") and not voyriaBlock then
    erAff("voyria")
    -- V2 integration: remove voyria with certainty
    if removeAffV2 then removeAffV2("voyria") end
    if removeAffV3 then removeAffV3("voyria") end
  else
    ataxiaTemp.randomCure = 1
    -- V2 integration: passive cured a random affliction
    if reduceRandomAffCertaintyV2 then reduceRandomAffCertaintyV2() end
    if onPassiveCureV3 then onPassiveCureV3(1) end
  end
	selectString(line,1)
	fg("NavajoWhite")
	resetFormat()
	targetIshere = true
 
 tBals.passive = false
 tempTimer(14.9,[[tBals.passive = true]])
  
end
