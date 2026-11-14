--[[mudlet
type: trigger
name: Rage (Knight)
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
  isMultiline: 'yes'
  isPerlSlashGOption: 'no'
  isColorizerTrigger: 'no'
  isFilterTrigger: 'no'
  isSoundTrigger: 'no'
  isColorTrigger: 'no'
  isColorTriggerFg: 'no'
  isColorTriggerBg: 'no'
triggerType: 0
conditonLineDelta: 1
mStayOpen: 0
mCommand: ''
packageName: ''
mFgColor: '#ff0000'
mBgColor: '#ffff00'
mSoundFile: ''
colorTriggerFgColor: '#000000'
colorTriggerBgColor: '#000000'
patterns:
- pattern: ^(\w+)'s eyes flash with rage.$
  type: 1
- pattern: '1'
  type: 5
- pattern: (.*)
  type: 1
]]--

local name = multimatches[1][2]
if isTargeted(name) then
	if multimatches[3][1] == name .. " gives a sigh of relief." then
		onClassCureV3({"retribution"})
		if startPassiveCooldownV3 then startPassiveCooldownV3("passive_rage") end
	elseif multimatches[3][1] == name .. " shakes his head and a look of clarity returns to his eyes."
		or multimatches[3][1] == name .. " shakes her head and a look of clarity returns to her eyes." then
			onClassCureV3({"lovers"})
			if startPassiveCooldownV3 then startPassiveCooldownV3("passive_rage") end
	else
		-- RAGE cures "certain pacifying afflictions, notably those that are normally cured by eating
		-- bellwort" (ABADMIN 541/2960/2990/3020, one per knight skill set). taRaged (curing/002) takes
		-- retribution and the first of 7 bellwort afflictions it holds; the game's list has 11. Until
		-- 2026-11-13 this branch also took paralysis. No source said so; the knight's paralysis cure is
		-- CONTINUATION (018).
		taRaged()
		if startPassiveCooldownV3 then startPassiveCooldownV3("passive_rage") end
	end
	targetIshere = true
end