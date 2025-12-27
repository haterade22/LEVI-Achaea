--[[mudlet
type: trigger
name: Scout
hierarchy:
- mudlet-mapper
- Mudlet Mapper
- Imperian
attributes:
  isActive: 'no'
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
- pattern: '   '
  type: 2
- pattern: ^   .+ at (.+)$
  type: 1
]]--

-- bad, overzealous trigger - the pattern needs to be improved
mmp.roomEcho(multimatches[2][2]) 