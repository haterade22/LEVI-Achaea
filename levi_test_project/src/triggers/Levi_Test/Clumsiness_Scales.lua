if type(target) == "string" and isTargeted(matches[2]) then
	tarAffed("clumsiness")
	if applyAffV3 then applyAffV3("clumsiness") end
end

if ataxiaBasher.enabled then
  if not ataxiaBasher.manual then
    deleteFull()
  end
end