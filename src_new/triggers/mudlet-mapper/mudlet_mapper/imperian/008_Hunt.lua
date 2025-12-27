--[[mudlet
type: trigger
name: Hunt
hierarchy:
- mudlet-mapper
- Mudlet Mapper
- Imperian
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
- pattern: ^You sense that (\w+) has entered (.+)\, (.+)\.$
  type: 1
]]--

selectCurrentLine()
replace("")
cecho("<chocolate>" .. matches[2] .. "<grey> moved to <sienna>" .. matches[3] .. ", <white>" ..matches[4])
mmp.roomEcho(matches[3]) 