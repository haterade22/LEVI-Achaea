--[[mudlet
type: trigger
name: Dragonheal
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
- pattern: ^(\w+) lets out a great keening, casting the impurities from \w+ form.$
  type: 1
]]--

local name = matches[2]

-- Dragonheal is blocked only by weariness AND recklessness TOGETHER (HELP, kb/afflictions/
-- class-cures.md), so seeing it proves "not both" -- never that either one is absent. Until
-- 2026-10-10 this erased both outright. It cures three afflictions, but only ONE while prone.
if isTargeted(matches[2]) then
	local cures = haveAff("prone") and 1 or 3
	ataxiaTemp.randomCure = cures
	onClassCureV3(nil, cures)
	if startPassiveCooldownV3 then startPassiveCooldownV3("passive_dragonheal") end
	selectString(line,1)
	fg("NavajoWhite")
	resetFormat()
	targetIshere = true
end
