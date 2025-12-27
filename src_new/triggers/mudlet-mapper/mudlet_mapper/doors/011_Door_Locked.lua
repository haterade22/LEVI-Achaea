--[[mudlet
type: trigger
name: Door Locked
hierarchy:
- mudlet-mapper
- Mudlet Mapper
- Doors
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
- pattern: The door is locked.
  type: 3
- pattern: The (?:walnut|pine|oak|iron|reinforced) door is locked\.
  type: 1
- pattern: The door is locked shut.
  type: 3
]]--

mmp.unlockDoor()