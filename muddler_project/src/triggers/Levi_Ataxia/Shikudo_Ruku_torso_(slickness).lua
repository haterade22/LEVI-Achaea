if isTargeted(matches[2]) then
  if not ignoreThirdPerson then
    tarAffed("slickness")
    if applyAffV3 then applyAffV3("slickness") end
  else
    ignoreThirdPerson = nil
  end
end
