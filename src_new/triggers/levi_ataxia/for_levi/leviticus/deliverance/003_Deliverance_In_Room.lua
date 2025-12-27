--[[mudlet
type: trigger
name: Deliverance In Room
hierarchy:
- Levi_Ataxia
- For Levi
- leviticus
- Ataxia
- Combat/Aff Tracking
- Misc Tracking
- Warnings
- Warnings
- Instakills
- Deliverance
attributes:
  isActive: 'yes'
  isFolder: 'no'
  isTempTrigger: 'no'
  isMultiline: 'yes'
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
- pattern: glowing white nimbus
  type: 0
- pattern: ([^\.]+) is here(?:\.|, sleeping soundly\.|, shrouded\.) (\w+) is surrounded by a glowing white nimbus\.
  type: 1
]]--

local person = multimatches[2][2]:trim()

if selectString(person, 1) > 0 then fg("red") setBold(true) deselect() resetFormat() end
ataxia_setWarning("deliverance in room", 1)