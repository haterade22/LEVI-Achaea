if line:find("crunch") then
  tarAffed("epilepsy")
  if applyAffV3 then applyAffV3("epilepsy") end
elseif isTargeted(matches[2]) then
	tarAffed("impatience")
	if applyAffV3 then applyAffV3("impatience") end
end

