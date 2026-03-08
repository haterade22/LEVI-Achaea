if not isTargeted(matches[2]) then return end
selectString(line,1)
fg("black")
if matches[3] == "mind" and haveAff("unweavingmind") then
	tarAffed("criticalmind")
  mindinvert = true
	bg("LightSkyBlue")
elseif matches[3] == "body" and haveAff("unweavingbody") then
	tarAffed("criticalbody")
  bodyinvert = true
  bg("chocolate")
else
  tarAffed("criticalspirit")
  spiritinvert = true
  bg("NavajoWhite")
end
deselect()