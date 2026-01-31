--[[mudlet
type: trigger
name: Time Loop
hierarchy:
- Levi_Ataxia
- For Levi
- leviticus
- Ataxia
- Combat/Aff Tracking
- Add Afflictions
- Classes A-J
- Depthwalker
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
- pattern: ^Grey fog begins to rise from the suddenly panicked-looking (\w+).$
  type: 1
]]--

if isTargeted(matches[2]) then
	checkTimeloop = true
	tarAffed("timeloop")
	if applyAffV3 then applyAffV3("timeloop") end
  erAff("haemophilia")
  if removeAffV3 then removeAffV3("haemophilia") end
  tloop = false
  tloop2 = false
  erAff("paralysis")
  if removeAffV3 then removeAffV3("paralysis") end
end