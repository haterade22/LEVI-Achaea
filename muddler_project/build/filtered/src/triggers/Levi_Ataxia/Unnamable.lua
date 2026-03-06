local num = tonumber(matches[3])
if isTargeted(matches[2]) then
	if num == 1 then
		tarAffed("stupidity")
		if applyAffV3 then applyAffV3("stupidity") end
	elseif num == 2 then
		tarAffed("stupidity", "confusion")
		if applyAffV3 then applyAffV3("stupidity"); applyAffV3("confusion") end
	else
		tarAffed("stupidity", "confusion", "dementia")
		if applyAffV3 then applyAffV3("stupidity"); applyAffV3("confusion"); applyAffV3("dementia") end
	end
	if readAuraAffs and readAuraAffs.count then
		readAuraAffs.count = readAuraAffs.count + num 
	end
  
  predictBal("eq", 2.4)	
end