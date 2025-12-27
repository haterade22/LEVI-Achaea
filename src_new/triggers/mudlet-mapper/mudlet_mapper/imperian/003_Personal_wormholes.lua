--[[mudlet
type: trigger
name: Personal wormholes
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
- pattern: You sense a personal wormhole at
  type: 2
- pattern: ^You sense a personal wormhole at (.+). It is attached to (.+)\.$
  type: 1
]]--

selectCurrentLine()
replace("")
mmp.echon("Personal wormhole at " .. multimatches[2][2])
mmp.roomEcho(multimatches[2][2])
echo(". It is attached to " .. multimatches[2][3] .. ".\n")