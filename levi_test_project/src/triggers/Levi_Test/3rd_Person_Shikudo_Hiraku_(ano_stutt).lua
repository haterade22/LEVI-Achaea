if isTargeted(matches[2]) then
  if not ignoreThirdPerson then
    tarAffed("anorexia", "stuttering")
    if applyAffV3 then applyAffV3("anorexia"); applyAffV3("stuttering") end
  else
    ignoreThirdPerson = nil
  end
end