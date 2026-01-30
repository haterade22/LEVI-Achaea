if type(target) == "string" and isTargeted(matches[2]) then
	tarAffed("weariness")
end

if ataxiaBasher.enabled then
  if not ataxiaBasher.manual then
    deleteFull()
  end
end