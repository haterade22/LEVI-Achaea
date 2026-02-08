local x = tonumber(matches[2])
ataxiaTemp.conviction = x
selectString(matches[2],1)
if x > 75 then
	fg("black")
	bg("goldenrod")
elseif x >= 50 then
	fg("green")
elseif x >= 25 then
	fg("red")
else
	fg("NavajoWhite")
end
deselect()

