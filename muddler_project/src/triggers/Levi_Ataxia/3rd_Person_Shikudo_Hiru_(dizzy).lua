if isTargeted(matches[2]) then
  if not ignoreThirdPerson then
    tarAffed("dizziness")
  else
    ignoreThirdPerson = nil
  end
end