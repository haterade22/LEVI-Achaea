--[[mudlet
type: trigger
name: Wormholes
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
- pattern: You sense a stable wormhole between
  type: 2
- pattern: ^You sense a stable wormhole between (.+?) and (.+)\.$
  type: 1
]]--

local room1 = mmp.roomEcho(multimatches[2][2])
local room2 = mmp.roomEcho(multimatches[2][3])
selectCurrentLine()
replace("")
mmp.echon("Stable wormhole between " .. room1)
mmp.roomEcho(room1)
echo(" and " .. room2)
mmp.roomEcho(room2)
echo(".\n")