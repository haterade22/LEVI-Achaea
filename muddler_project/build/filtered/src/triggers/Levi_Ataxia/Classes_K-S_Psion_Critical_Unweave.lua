if not isTargeted(matches[2]) then return end
selectString(line,1)
fg("black")
if matches[3] == "mind" and haveAff("unweavingmind") then
	tAffs.criticalmind = true
  mindinvert = true
	bg("LightSkyBlue")
elseif matches[3] == "body" and haveAff("unweavingbody") then
	tAffs.criticalbody = true
  bodyinvert = true
  bg("chocolate")
else
  tAffs.criticalspirit = true
  spiritinvert = true
  bg("NavajoWhite")
end
deselect()