if line:find("disembowelment") then
  erAff("impaled")
  if removeAffV3 then removeAffV3("impaled") end
tAffs.impaled = false
timpale = false
  -- BM Brokenstar phase engine callback
  if blademaster and blademaster.onTargetUnimpaled then blademaster.onTargetUnimpaled() end
else
  if isTargeted(matches[2]) then
  	erAff("impaled")
  	if removeAffV3 then removeAffV3("impaled") end
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
