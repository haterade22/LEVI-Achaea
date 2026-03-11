local name = matches[2]
local class = (ataxiaNDB_getClass(name) or "Unknown")

if isTargeted(name) and class == "Priest" then
  -- Priest healing cures voyria if present, else 1 random
  if haveAff("voyria") then
    erAff("voyria")
    if removeAffV2 then removeAffV2("voyria") end
  else
    ataxiaTemp.randomCure = 1
    if reduceRandomAffCertaintyV2 then reduceRandomAffCertaintyV2() end
    if onPassiveCureV3 then onPassiveCureV3(1) end
  end
  selectString(line,1)
  fg("NavajoWhite")
  resetFormat()
  targetIshere = true
end
