--[[mudlet
type: trigger
name: Each person
hierarchy:
- Levi_Ataxia
- For Levi
- leviticus
- Ataxia
- Combat/Aff Tracking
- Add Afflictions
- Classes A-J
- Fullsense-Hyena
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
- pattern: ^(\w+) is at (.+?) on (\d+) out of (\d+)\.$
  type: 1
]]--

mmp.locateAndEchoSide(matches[3], matches[2])

fullSensePeople[matches[3]] = fullSensePeople[matches[3]] or {}
table.insert(fullSensePeople[matches[3]], matches[2])
table.sort(fullSensePeople[matches[3]])
deleteLine()