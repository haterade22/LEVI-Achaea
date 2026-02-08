if not isTargeted(matches[2]) then return end
selectString(line,1)
fg("black")
if matches[3] == "mind" and haveAff("unweavingmind") then
	tAffs.criticalmind = true
	if applyAffV3 then applyAffV3("criticalmind") end
  mindinvert = true
	bg("LightSkyBlue")
elseif matches[3] == "body" and haveAff("unweavingbody") then
	tAffs.criticalbody = true
	if applyAffV3 then applyAffV3("criticalbody") end
  bodyinvert = true
  bg("chocolate")
else
  tAffs.criticalspirit = true
  if applyAffV3 then applyAffV3("criticalspirit") end
  spiritinvert = true
  bg("NavajoWhite")
end
deselect()