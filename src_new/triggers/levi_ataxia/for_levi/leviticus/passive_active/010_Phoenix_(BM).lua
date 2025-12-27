--[[mudlet
type: trigger
name: Phoenix (BM)
hierarchy:
- Levi_Ataxia
- For Levi
- leviticus
- Ataxia
- Combat/Aff Tracking
- Remove Afflictions
- Groups
- Passive/Active
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
- pattern: ^Throwing back \w+ head\, (\w+) shouts out in defiance as blazing flames consume \w+ for a single, glorious instant
    before dying away\.$
  type: 1
]]--

local name = matches[2]
local class = (ataxiaNDB_getClass(name) or "Unknown")

if isTargeted(matches[2]) and class == "Blademaster" and not haveAff("prone") then
  tAffs = {blindness = false, deafness = false, shield = false, rebounding = false, curseward = false}
	selectString(line,1)
	fg("NavajoWhite")
  ataxia_boxEcho("PHOENIXED! AFFS RESET", "purple")
	resetFormat()
	targetIshere = true
end
