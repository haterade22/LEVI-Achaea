--[[mudlet
type: trigger
name: Trap List
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
- pattern: '   '
  type: 2
- pattern: ^   (\w+) \((\w+)\) at (.+)$
  type: 1
]]--

-- the first pattern is not blank, there are spaces there

selectCurrentLine()
replace("")
echo("[" .. multimatches[2][2] .. "] (" .. multimatches[2][3] .. ") at " .. multimatches[2][4])
mmp.roomEcho(multimatches[2][4]) 