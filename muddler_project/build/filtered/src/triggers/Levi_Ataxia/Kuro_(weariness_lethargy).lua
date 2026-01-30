if isTargeted(matches[3]) then
  if not ignoreThirdPerson then
    if haveAff("weariness") then
      tarAffed("lethargy")
    else
      tarAffed("weariness")
    end
  else
    ignoreThirdPerson = nil    
  end
end