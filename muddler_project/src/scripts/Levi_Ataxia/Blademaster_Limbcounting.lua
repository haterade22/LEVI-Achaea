function ataxia_updateBlademasterStance()
  if ataxiaTables.limbData.bmBaseSlash == 0 or ataxiaTables.limbData.bmBaseCompass == 0 then return end
  local stanceDiff = {
    Sanya = 1.06,
    Arash = 1.16,
    Thyr = 0.85,
    Mir = 0.95,     
  }
  local stance = ataxia.vitals.stance
  ataxiaTables.limbData.bmCompass = ( ataxiaTables.limbData.bmBaseCompass * stanceDiff[stance] )
  ataxiaTables.limbData.bmOffSlash = ( ataxiaTables.limbData.bmBaseOffSlash * stanceDiff[stance] )
  ataxiaTables.limbData.bmSlash = ( ataxiaTables.limbData.bmBaseSlash * stanceDiff[stance] )
  cecho("\n<green> -= predicted stance modifiers updated =-")
end

function ataxia_updateBlademasterBases()
  local stanceDiff = {
    Sanya = 0.94,
    Arash = 0.84,
    Thyr = 1.15,
    Mir = 1.05,     
  }
  local stance = ataxia.vitals.stance
  ataxiaTables.limbData.bmBaseCompass = ( ataxiaTables.limbData.bmCompass * stanceDiff[stance] )
  ataxiaTables.limbData.bmBaseOffSlash = ( ataxiaTables.limbData.bmOffSlash * stanceDiff[stance] )
  ataxiaTables.limbData.bmBaseSlash = ( ataxiaTables.limbData.bmSlash * stanceDiff[stance] )  
end

function ataxia_blademasterNeedComp()
  local one, two = ataxiaTables.limbData.bmSlash, ataxiaTables.limbData.bmOffSlash
  local left, right = 0, 0
  --10 rounds should more than suffice
  for i=1, 10 do
    --Add to first limb
    left = left + one; right = right + two
  
    --Check if left is broken here.
    if left > 99.99 and right < 99.99 then
      ataxiaTables.limbData.bmProblemslash = true
      cecho("\n<yellow> --> WE PREDICT COMPASSSLASH IS NEEDED!")
      cecho("\n<orange> --> WE PREDICT COMPASSSLASH IS NEEDED!")
      cecho("\n<red> --> WE PREDICT COMPASSSLASH IS NEEDED!")
      break
    end
  
    --Continue on if not
    left = left + two 
    right = right + one 
  end
  if ataxiaTables.limbData.bmProblemslash == nil then
    ataxiaTables.limbData.bmProblemslash = false
    cecho("\n<green> --> CompassSlash is not needed for this health.")
  end
end