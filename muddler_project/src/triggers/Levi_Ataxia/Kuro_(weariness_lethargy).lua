if isTargeted(matches[3]) then
  if not ignoreThirdPerson then
    if haveAff("weariness") then
      tarAffed("lethargy")
      if applyAffV3 then applyAffV3("lethargy") end
    else
      tarAffed("weariness")
      if applyAffV3 then applyAffV3("weariness") end
    end
  else
    ignoreThirdPerson = nil    
  end
end