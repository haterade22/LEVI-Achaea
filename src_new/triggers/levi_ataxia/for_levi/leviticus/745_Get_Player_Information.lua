--[[mudlet
type: trigger
name: Get Player Information
hierarchy:
- Levi_Ataxia
- For Levi
- leviticus
- Ataxia
- Ataxia NDB
attributes:
  isActive: 'no'
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
- pattern: ^(.+) \((male|female|fae|Fae) (.+)\).
  type: 1
]]--

if ataxiaNDB._honoursPerson and matches[2]:find(ataxiaNDB._honoursPerson) then
  getNDBCity = "None"
  ataxiaNDB._mark = false
  ataxiaNDB._armyRank = 0
  ataxiaNDB._dauntless = false
	enableTrigger("Additional Information NDB")
end
