--[[mudlet
type: trigger
name: Numbed Arms
hierarchy:
- Levi_Ataxia
- For Levi
- leviticus
- LeviAtax
- Leviticus
- Runie
- DWB
- Dual Blunt
attributes:
  isActive: 'yes'
  isFolder: 'no'
  isTempTrigger: 'no'
  isMultiline: 'no'
  isPerlSlashGOption: 'no'
  isColorizerTrigger: 'no'
  isFilterTrigger: 'no'
  isSoundTrigger: 'no'
  isColorTrigger: 'no'
  isColorTriggerFg: 'no'
  isColorTriggerBg: 'no'
triggerType: 0
conditonLineDelta: 0
mStayOpen: 0
mCommand: ''
packageName: ''
mFgColor: '#ff0000'
mBgColor: '#ffff00'
mSoundFile: ''
colorTriggerFgColor: '#000000'
colorTriggerBgColor: '#000000'
patterns:
- pattern: ^You feel the satisfying crunch of bone as your attack connects with the (\w+) arm of (\w+).$
  type: 1
]]--

if isTargeted(matches[3]) then
tparrying = "none"
dwbparrying = false
ataxiaTemp.parriedLimb = "none"
tempTimer(15, [[ tAffs.numbedleftarm = nil;cecho("\n<a_darkgreen>target can parry again");erAff("numbedleftarm") ; if removeAffV3 then removeAffV3("numbedleftarm") end]])
	if matches[2] == "right" then
    if numbedRight then killTimer(numbedRight) end
    numbedRight = tempTimer(15, [[ tAffs.numbedrightarm = nil; cecho("\n<green>target can use tattoos again");erAff("numbedrightarm") ; if removeAffV3 then removeAffV3("numbedrightarm") end]])
    tarAffed("numbedrightarm")
    if applyAffV3 then applyAffV3("numbedrightarm") end
  else
    if numbedLeft then killTimer(numbedLeft) end
    numbedLeft = tempTimer(15, [[ tAffs.numbedleftarm = nil; cecho("\n<a_darkgreen>target can parry again");erAff("numbedleftarm") ; if removeAffV3 then removeAffV3("numbedleftarm") end]])
    tarAffed("numbedleftarm")  
    if applyAffV3 then applyAffV3("numbedleftarm") end
  end
end