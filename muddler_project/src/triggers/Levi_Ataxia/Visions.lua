if isTargeted(matches[2]) then
  if haveAff("dementia") then
    tarAffed("shyness")
    if applyAffV3 then applyAffV3("shyness") end
  else
    tarAffed("dementia")
    if applyAffV3 then applyAffV3("dementia") end
	end
end