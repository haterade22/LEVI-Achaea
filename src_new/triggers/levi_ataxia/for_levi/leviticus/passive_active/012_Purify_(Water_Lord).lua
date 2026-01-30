--[[mudlet
type: trigger
name: Purify (Water Lord)
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
- pattern: ^The amorphous form of (\w+) trembles, some of the liquid composing it falling away from the greater whole.$
  type: 1
- pattern: ^The water that (\w+) stands upon rises up to become a part of \w+.$
  type: 1
]]--

local name = matches[2]
if isTargeted(matches[2]) then
  erAff("weariness")
	ataxiaTemp.randomCure = 1
	-- V2 integration: Purify cures weariness + 1 random
	if removeAffV2 then removeAffV2("weariness") end
	if reduceRandomAffCertaintyV2 then reduceRandomAffCertaintyV2() end
	selectString(line,1)
	fg("NavajoWhite")
	resetFormat()
	targetIshere = true
end