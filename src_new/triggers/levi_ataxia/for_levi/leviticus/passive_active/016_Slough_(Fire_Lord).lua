--[[mudlet
type: trigger
name: Slough (Fire Lord)
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
- pattern: ^The fiery outer layers of (\w+) fall away\, turning to dust as they drift to the ground\. Though (\w+) seems diminished
    for an instant\, \w+ fires soon rage with fury once more\.$
  type: 1
]]--

local name = matches[2]
if isTargeted(matches[2]) then
	ataxiaTemp.randomCure = 1
	-- V2 integration: Slough cures 1 random affliction
	if reduceRandomAffCertaintyV2 then reduceRandomAffCertaintyV2() end
	selectString(line,1)
	fg("NavajoWhite")
	resetFormat()
	targetIshere = true
end