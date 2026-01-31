if tAffs.bleed == nil then tAffs.bleed = 0 end
tAffs.bleed = tAffs.bleed + 50
selectString(line,1)
if tAffs.bleed < 200 then
  --don't colour it
elseif tAffs.bleed < 400 then
  fg("NavajoWhite")
elseif tAffs.bleed < 600 then
  fg("orange")
else
  fg("firebrick")
end
deselect()
resetFormat()