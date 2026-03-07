if isTargeted(matches[2]) then
  -- Shrugging: cures weariness + 1 random affliction
  erAff("weariness")
  ataxiaTemp.randomCure = 1
  if removeAffV2 then removeAffV2("weariness") end
  if removeAffV3 then removeAffV3("weariness") end
  if reduceRandomAffCertaintyV2 then reduceRandomAffCertaintyV2() end
  if onPassiveCureV3 then onPassiveCureV3(1) end
  selectString(line,1)
  fg("NavajoWhite")
  resetFormat()
  targetIshere = true
end