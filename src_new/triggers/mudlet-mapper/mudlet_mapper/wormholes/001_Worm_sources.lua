--[[mudlet
type: trigger
name: Worm sources
hierarchy:
- mudlet-mapper
- Mudlet Mapper
- Wormholes
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
- pattern: You sense a connection between
  type: 2
- pattern: ^You sense a connection between (.*) and (.*).$
  type: 1
]]--

deleteLine()
local from,fromhouse = multimatches[2][2]:gsub(" %(house%)","")
local to,tohouse = multimatches[2][3]:gsub(" %(house%)","")
if fromhouse >= 1 then fromhouse = " (house)" else fromhouse = "" end
if tohouse >= 1 then tohouse = " (house)" else tohouse = "" end
cecho("\nYou see a connection between ".. from .. fromhouse .. " (")
mmp.echonums(from, gmcp.Room.Info.area)
cecho(") and "..to..tohouse.." (")
mmp.echonums(to)
cecho(")")
