if type(target) == "string" and isTargeted(matches[2]) then
	tarAffed("asthma")
	if applyAffV3 then applyAffV3("asthma") end
end

if ataxiaBasher.enabled then
  if not ataxiaBasher.manual then
    deleteFull()
  end
end