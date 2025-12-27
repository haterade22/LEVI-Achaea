--[[mudlet
type: trigger
name: Trap went off
hierarchy:
- mudlet-mapper
- Mudlet Mapper
- Imperian
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
- pattern: Your alarm at
  type: 2
- pattern: ^Your alarm at \'(.+)\' has been set off by (\w+)\!$
  type: 1
]]--

selectCurrentLine()
replace("")
mmp.echon("Your trap at " .. multimatches[2][2])
mmp.roomEcho(multimatches[2][2])
echo(" was set off by " .. multimatches[2][3] .. "!!!\n")