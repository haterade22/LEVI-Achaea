if isTargeted(matches[2]) then
  if not ignoreThirdPerson then
    tarAffed("addiction")
    if applyAffV3 then applyAffV3("addiction") end
  else
    ignoreThirdPerson = nil
  end
end