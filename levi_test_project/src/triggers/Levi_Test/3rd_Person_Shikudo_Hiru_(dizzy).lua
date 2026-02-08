if isTargeted(matches[2]) then
  if not ignoreThirdPerson then
    tarAffed("dizziness")
    if applyAffV3 then applyAffV3("dizziness") end
  else
    ignoreThirdPerson = nil
  end
end