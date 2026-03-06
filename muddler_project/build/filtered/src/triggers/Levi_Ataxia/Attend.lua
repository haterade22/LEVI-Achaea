if isTargeted(matches[2]) then
	tAffs.blindness = false
	if removeAffV3 then removeAffV3("blindness") end
	tAffs.deafness = false
	if removeAffV3 then removeAffV3("deafness") end
  
  predictBal("eq", 2)	
end