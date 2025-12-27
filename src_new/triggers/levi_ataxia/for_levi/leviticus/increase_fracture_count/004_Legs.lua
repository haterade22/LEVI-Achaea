--[[mudlet
type: trigger
name: Legs
hierarchy:
- Levi_Ataxia
- For Levi
- leviticus
- Ataxia
- Combat/Aff Tracking
- Add Afflictions
- Affs Post Queue - Gated
- Classes K-S
- Knight
- Two-hander
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
- pattern: ^(\w+) almost falls as the hammer crunches home into the bones of (\w+) lower (right|left) leg.$
  type: 1
- pattern: ^(\w+) almost falls as the blade savagely bites into (\w+) lower (right|left) leg.$
  type: 1
]]--

if isTargeted(matches[2]) then
	if ataxiaTemp.thfocus == "precision" then
    twohanded_increaseFracture("torntendons", 2)
	else
		twohanded_increaseFracture("torntendons", 1)
	end
  ataxiaTemp.lastLimbHit = matches[4].."leg"
  twohanded_legsHit()

  if not ataxia.vitals.bal then
    ataxia_setAffPrio("paralysis", 25)
    tempTimer(1, [[ ataxia_restorePrio("paralysis") ]])
  end 
end