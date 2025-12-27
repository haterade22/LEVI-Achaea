--[[mudlet
type: trigger
name: Door in the way
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
- pattern: There is a door in the way, to the
  type: 2
- pattern: There is a door in the way.
  type: 3
- pattern: A closed door is in the way. You need to OPEN DOOR
  type: 2
- pattern: There is an? (?:walnut|pine|oak|iron|reinforced) door in the way.
  type: 1
- pattern: The door to the (\w+) is closed.
  type: 1
- pattern: There is a closed door in the way.
  type: 3
- pattern: The (?:gate|door|way) to the \w+ is closed.
  type: 1
- pattern: The \w+ (?:gate|door) to the \w+ is closed.
  type: 1
- pattern: ^The (?:cellar door|manhole) (?:up|down) is closed.
  type: 1
- pattern: The \w+ in that direction is closed.
  type: 1
]]--

mmp.openDoor()