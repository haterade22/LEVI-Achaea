--[[mudlet
type: trigger
name: Devolve
hierarchy:
- Levi_Ataxia
- For Levi
- leviticus
- Ataxia
- Combat/Aff Tracking
- Add Afflictions
- Classes K-S
- Occultist
- Occultism
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
- pattern: ^You utter a terrible curse and point a finger at (\w+).$
  type: 1
- pattern: ^(\w+)'s body seems to weaken and appears more primitive.$
  type: 1
- pattern: ^\w+ utters a terrible curse and points a finger at (\w+).$
  type: 1
]]--

if isTargeted(matches[2]) then
  tarAffed("shyness", "disloyalty")
  
  predictBal("eq", 2.1)	
end