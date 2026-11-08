--[[mudlet
type: trigger
name: Stood Up
hierarchy:
- Levi_Ataxia
- For Levi
- leviticus
- Ataxia
- Combat/Aff Tracking
- Remove Afflictions
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
- pattern: ^(\w+) stands up.$
  type: 1
]]--

if isTargeted(matches[2]) then
	local rem = {"prone", "paralysis", "brokenleftleg", "damagedleftleg", "brokenrightleg", "damagedrightleg"}
	-- The limb counter may have no row for this name. limb/001 makes one from the game's "Your target
	-- is now: X (an adventurer)" or "(a denizen)" line, under the name as typed, and the game sets a
	-- name that is no adventurer's as a denizen: `st Sabi`, a mistyped Saibel, gave "Your target is
	-- now: Sabi (a denizen)" (kb/raw/logs/ours/2026-11-07_164635_Saibel.log:111-118). So a
	-- part name (`st Sai`) has its row as Sai, and isTargeted just above completes the target to
	-- Saibel, which has none. Indexing the missing row threw, so the prone and leg erases below never
	-- ran on a stand (2026-11-08 deep review).
	local limbs = lb and lb[target] and lb[target].hits
	if limbs then
		if (limbs["left leg"] or 0) >= 100 then limbs["left leg"] = 0 end
		if (limbs["right leg"] or 0) >= 100 then limbs["right leg"] = 0 end
	end
	for _, aff in pairs(rem) do
		erAff(aff)
	end
  tAffs.prone = false
  erAff("prone")
end