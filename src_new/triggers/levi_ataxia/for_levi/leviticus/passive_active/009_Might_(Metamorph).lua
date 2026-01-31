--[[mudlet
type: trigger
name: Might (Metamorph)
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
- pattern: ^(\w'+) lets out a mighty roar\.$
  type: 1
]]--

local name = matches[2]
local class = (ataxiaNDB_getClass(name) or "Unknown")

if isTargeted(matches[2]) and (class == "Druid" or class == "Sentinel") then
  erAff("prone")
	ataxiaTemp.randomCure = 1
	-- V2 integration: Might cures prone + 1 random
	if removeAffV2 then removeAffV2("prone") end
	if removeAffV3 then removeAffV3("prone") end
	if reduceRandomAffCertaintyV2 then reduceRandomAffCertaintyV2() end
	if onPassiveCureV3 then onPassiveCureV3(1) end
	selectString(line,1)
	fg("NavajoWhite")
	resetFormat()
	targetIshere = true
end
