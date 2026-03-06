if isTargeted(matches[2]) then
  if not ignoreThirdPerson then
    tarAffed("crushedthroat")
    if applyAffV3 then applyAffV3("crushedthroat") end
  else
    ignoreThirdPerson = nil
  end
end