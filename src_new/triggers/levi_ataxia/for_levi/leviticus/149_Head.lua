--[[mudlet
type: trigger
name: Head
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
- pattern: ^(\w+) staggers as the blade strikes (\w+) in the side of the head.$
  type: 1
- pattern: ^(\w+) staggers back as the hammer catches (\w+) a glancing blow to the head.$
  type: 1
]]--

if isTargeted(matches[2]) then
	if ataxiaTemp.thfocus == "precision" then
    twohanded_increaseFracture("skullfractures", 2)
	else
		twohanded_increaseFracture("skullfractures", 1)
	end
  ataxiaTemp.lastLimbHit = "head"
  twohanded_headHit()
  
  if not ataxia.vitals.bal then
    ataxia_setAffPrio("paralysis", 25)
    tempTimer(1, [[ ataxia_restorePrio("paralysis") ]])
  end
end