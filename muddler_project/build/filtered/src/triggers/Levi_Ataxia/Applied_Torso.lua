if isTargeted(matches[2]) then
tdeliverance = false
  if passiveFailsafe then restorePassiveCure() end
  -- V3 integration: torso salve cure branching
  if onSalveCureV3 then onSalveCureV3("torso") end
  erAff("slickness")
	erAff("bloodfire")
  erAff("selarnia")
  erAff("frostbite")
  
  local salvetimer = false
  if haveAff("hypothermia") then
    if haveAff("timeflux") then
      tempTimer(6.5, [[ erAff("hypothermia"); ataxia_boxEcho("they cured hypothermia", "DodgerBlue") ]])
      salvetimer = 6.5
    else
      tempTimer(3.5, [[ erAff("hypothermia"); ataxia_boxEcho("they cured hypothermia", "DodgerBlue") ]])
      salvetimer = 3.5
      target_salveBal(4)
    end
  elseif tLimbs.T >= 98 then
    tempTimer(4, [[ target_resetLimb("torso")]])
    salvetimer = 3.5
    target_salveBal(4)
   else 
    target_salveBal(4)
  end
  
  
  if lb[target].hits["torso"] >= 100 and lb[target].hits["torso"] < 200 then
    tempTimer(4, [[erAff("mildtrauma");ataxia_boxEcho("they cured TORSO", "DodgerBlue")]])
    target_salveBal(4)
  elseif lb[target].hits["torso"] >= 200 then
    tempTimer(4, [[erAff("serioustrauma")]])
    target_salveBal(4)
  else 
    target_salveBal(4)
  end
  if salvetimer ~= false then
    target_salveBal(salvetimer)
  end
  
	erAff("bloodfire")
	targetIshere = true
end