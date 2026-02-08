if not isTargeted(matches[2]) then return end

selectString(line,1)
fg("LightSkyBlue")
tAffs.worms = true
if applyAffV3 then applyAffV3("worms") end
predictBal("class", 1.8)	