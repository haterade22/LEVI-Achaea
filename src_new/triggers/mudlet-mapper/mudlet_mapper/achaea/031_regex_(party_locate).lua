--[[mudlet
type: trigger
name: regex (party locate)
hierarchy:
- mudlet-mapper
- Mudlet Mapper
- Achaea
- Party traces/locaters
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
- pattern: '^\(Party\): \w+ says, "(\w+) moved to (.+)\."$'
  type: 1
- pattern: '^\(Party\): \w+ says, "(\w+) is at (.+), in (.+)\."'
  type: 1
- pattern: '^\(Party\): \w+ says, "Trace: (\w+) moved to (.+)\."'
  type: 1
- pattern: '^\(Party\): \w+ says, "(\w+) - (.+), in (.+)\."$'
  type: 1
- pattern: '^\(Party\): \w+ says, "(\w+) is at (.+) \(.+\)\."'
  type: 1
- pattern: '^\(Party\): \w+ says, "Trace: (\w+) entered (.+) in (.+)\."'
  type: 1
- pattern: '^\(Party\): \w+ says, "Trace: (\w+) entered (.+)\."'
  type: 1
]]--

mmp.locateAndEcho(matches[3], matches[2], matches[4])