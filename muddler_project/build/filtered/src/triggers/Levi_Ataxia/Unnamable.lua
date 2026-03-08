local num = tonumber(matches[3])
if isTargeted(matches[2]) then
	if num == 1 then
		tarAffed("stupidity")
	elseif num == 2 then
		tarAffed("stupidity", "confusion")
	else
		tarAffed("stupidity", "confusion", "dementia")
	end
	if readAuraAffs and readAuraAffs.count then
		readAuraAffs.count = readAuraAffs.count + num 
	end
  
  predictBal("eq", 2.4)	
end