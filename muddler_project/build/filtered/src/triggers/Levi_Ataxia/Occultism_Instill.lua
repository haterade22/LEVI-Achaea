if isTargeted(matches[2]) then
	tarAffed(matches[3])
	if applyAffV3 then applyAffV3(matches[3]) end
	if readAuraAffs and readAuraAffs.count then
		readAuraAffs.count = readAuraAffs.count + 1
	end
  
  predictBal("eq", 1.8)	
end