--[[mudlet
type: trigger
name: Check Player City
hierarchy:
- Levi_Ataxia
- For Levi
- leviticus
- Ataxia
- Ataxia NDB
- Additional Information NDB
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
- pattern: ^(He|She|Fae) is an? \w+ in (\w+).$
  type: 1
- pattern: ^(He|She|Fae) is an? .+ in The (\w+).$
  type: 1
- pattern: ^(He|She|Fae) is a .+ in The (\w+).$
  type: 1
]]--

if not honoursPerson then return end
ataxiaNDB.players[honoursPerson].city = matches[3]:title()

getNDBCity = matches[3]

selectString(matches[3], 1)
fg(ataxiaNDB.highlighting[matches[3]])
resetFormat()

raiseEvent("ataxiaNDB Check Highlight", honoursPerson)
