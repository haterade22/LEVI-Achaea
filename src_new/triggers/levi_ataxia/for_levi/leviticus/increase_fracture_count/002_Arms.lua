--[[mudlet
type: trigger
name: Arms
hierarchy:
- Levi_Ataxia
- For Levi
- leviticus
- LeviAtax
- Leviticus
- INFERNAL
- Fractures
- Increase Fracture Count
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
- pattern: ^The sickening crunch of bone can be heard as the blade smashes into the (right|left) arm of (\w+).$
  type: 1
- pattern: ^The wet crunch of bone can be heard as the hammer smashes into the (right|left) arm of (\w+).$
  type: 1
]]--

if isTargeted(matches[3]) then
	if ataxiaTemp.thfocus == "precision" then
    twohanded_increaseFracture("wristfractures", 2)
	else
		twohanded_increaseFracture("wristfractures", 1)
	end
  ataxiaTemp.lastLimbHit = matches[2].."arm"
  twohanded_armsHit()
  
  if not ataxia.vitals.bal then
    ataxia_setAffPrio("paralysis", 25)
    tempTimer(1, [[ ataxia_restorePrio("paralysis") ]])
  end
end