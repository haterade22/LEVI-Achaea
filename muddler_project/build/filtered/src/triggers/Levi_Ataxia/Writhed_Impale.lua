if line:find("disembowelment") then
  erAff("impaled")
tAffs.impaled = false
timpale = false
  -- BM Brokenstar phase engine callback
  if blademaster and blademaster.onTargetUnimpaled then blademaster.onTargetUnimpaled() end
else
  if isTargeted(matches[2]) then
  	erAff("impaled")
  	selectString(line,1)
  	setBold(true)
  	fg("magenta")
  	resetFormat()
tAffs.impaled = false
timpale = false
    -- BM Brokenstar phase engine callback
    if blademaster and blademaster.onTargetUnimpaled then blademaster.onTargetUnimpaled() end
  end
end
