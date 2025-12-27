--[[mudlet
type: trigger
name: Dragonsense
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
- pattern: Tapping into the unfathomable depths of your power, you sense that
  type: 2
- pattern: Tapping into the unfathomable depths of your power, you sense that (\w+) is at (.+), in (.+)\.$
  type: 1
]]--

mmp.locateAndEcho(multimatches[2][3], multimatches[2][2], multimatches[2][4])