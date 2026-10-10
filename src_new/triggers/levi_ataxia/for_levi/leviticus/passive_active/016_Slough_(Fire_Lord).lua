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
- pattern: ^The fiery outer layers of (\w+) fall away\, turning to dust
  type: 1
]]--

local name = matches[2]
if isTargeted(matches[2]) then
	-- Slough cures 1 random affliction and is blocked by PRONE (HELP, kb/afflictions/
	-- class-cures.md), so seeing it proves the target is not prone. Until 2026-10-10 it erased
	-- weariness instead, which nothing supports. The pattern was also the whole ~160-column line,
	-- which the server wraps at 119-124, so it could not match; it now stops at an early fragment.
	ataxiaTemp.randomCure = 1
	onClassCureV3({"prone"}, 1)
	if startPassiveCooldownV3 then startPassiveCooldownV3("passive_slough") end
	selectString(line,1)
	fg("NavajoWhite")
	resetFormat()
	targetIshere = true
end