--[[mudlet
type: trigger
name: Mindsense
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
- pattern: You seek out the mind of
  type: 2
- pattern: ^You seek out the mind of (\w+) and an image of (.+) appears in your mind\.$
  type: 1
]]--

mmp.locateAndEchoSide(multimatches[2][3], multimatches[2][2])