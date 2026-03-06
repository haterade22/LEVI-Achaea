if type(target) == "string" and isTargeted(matches[2]) then
	tarAffed("haemophilia")
	if applyAffV3 then applyAffV3("haemophilia") end
  
end

if not tAffs.haemophilia then
tarAffed("haemophilia") 
if applyAffV3 then applyAffV3("haemophilia") end
tAffs.bleed = tAffs.bleed + 50
end
if tAffs.haemophilia then
tAffs.bleed = tAffs.bleed + 100
end

if ataxiaBasher.enabled then
  if not ataxiaBasher.manual then
    deleteFull()
  end
end