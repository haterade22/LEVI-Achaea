if isTargeted(matches[3]) then
tparrying = "none"
dwbparrying = false
ataxiaTemp.parriedLimb = "none"
tempTimer(15, [[ tAffs.numbedleftarm = nil;cecho("\n<a_darkgreen>target can parry again") ]])
	if matches[2] == "right" then
    if numbedRight then killTimer(numbedRight) end
    numbedRight = tempTimer(15, [[ tAffs.numbedrightarm = nil; cecho("\n<green>target can use tattoos again") ]])
    tarAffed("numbedrightarm")
    if applyAffV3 then applyAffV3("numbedrightarm") end
 
  else
    if numbedLeft then killTimer(numbedLeft) end
    numbedLeft = tempTimer(15, [[ tAffs.numbedleftarm = nil; cecho("\n<a_darkgreen>target can parry again") ]])
    tarAffed("numbedleftarm")  
    if applyAffV3 then applyAffV3("numbedleftarm") end
  end
end