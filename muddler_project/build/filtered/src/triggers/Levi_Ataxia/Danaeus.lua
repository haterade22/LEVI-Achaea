if matches[1]:find("disregards") then
  tarAffed("vertigo")
  if applyAffV3 then applyAffV3("vertigo") end
elseif isTargeted(matches[2]) then
	tarAffed("vertigo")
	if applyAffV3 then applyAffV3("vertigo") end
  
  predictBal("class", 1.7)	
end