--[[mudlet
type: trigger
name: Failed to open door
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
- pattern: You are not carrying a key for this door.
  type: 3
- pattern: This door has been magically locked shut.
  type: 3
- pattern: Not recognising you as cast or crew, stagehands firmly close the door on you.
  type: 3
- pattern: You push against the door in vain as you try to open it.
  type: 3
- pattern: You do not have access to open this door.
  type: 3
- pattern: The door beeps quietly. It appears to be locked.
  type: 3
- pattern: This (?:walnut|pine|oak|iron|reinforced) door has been magically locked shut\.
  type: 1
- pattern: You are not carrying a key for this (?:walnut|pine|oak|iron|reinforced) door\.
  type: 1
- pattern: The door has been magically locked shut.
  type: 3
- pattern: You must have a lockpick in order to attempt to open the exit.
  type: 0
- pattern: You need to seek training before being able to pick locks.
  type: 0
]]--

mmp.failpath()