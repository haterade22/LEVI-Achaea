if isTargeted(matches[2]) then
  if matches[5] == "legs" then
    twohanded_decreaseFracture("torntendons")
  elseif matches[5] == "arms" then
    twohanded_decreaseFracture("wristfractures")
  elseif matches[5] == "head" then
    twohanded_decreaseFracture("skullfractures")
  elseif matches[5] == "torso" then
    twohanded_decreaseFracture("crackedribs")
  end
end