if type(target) == "string" and isTargeted(matches[2]) then
	tarAffed("paralysis")
	if applyAffV3 then applyAffV3("paralysis") end
end

if ataxiaBasher.enabled then
  if not ataxiaBasher.manual then
    deleteFull()
  end
end