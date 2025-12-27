--[[mudlet
type: trigger
name: Oppression Predator
hierarchy:
- mudlet-mapper
- Mudlet Mapper
- Achaea
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
conditonLineDelta: 1
mStayOpen: 0
mCommand: ''
packageName: ''
mFgColor: '#ff0000'
mBgColor: '#ffff00'
mSoundFile: ''
colorTriggerFgColor: '#000000'
colorTriggerBgColor: '#000000'
patterns:
- pattern: Your oppressive gaze sweeps across the land, seeking out your prey.
  type: 3
- pattern: '1'
  type: 5
- pattern: ^You see that (\w+) (?:conquers|) at (.+)\.$
  type: 1
]]--

mmp.locateAndEchoSide(multimatches[3][3], multimatches[3][2])