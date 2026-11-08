--[[mudlet
type: trigger
name: Goldenseal (Madness)
hierarchy:
- Levi_Ataxia
- For Levi
- leviticus
- Ataxia
- Combat/Aff Tracking
- Remove Afflictions
- Herbs
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
- pattern: ^(\w+) eats a (goldenseal root|plumbum flake).$
  type: 1
]]--


if isTargeted(matches[2]) then
tdeliverance = false
	if anorexiaFailsafe then
		tAffs[lastFocus] = true
		ataxiaEcho("Backtracked anorexia being cured with last focus.")
		anorexiaFailsafe = nil
		lastFocus = nil
	end
	-- The eat is charged now as a random cure, and the branches from before it are kept: when the
	-- next line names the cure ("Lucidity returns to the eyes of X." -> shadowmadness, third-person
	-- _removes/003; "X ceases his violent trembling." -> mycalium, 004), that trigger puts them back
	-- and charges the named one alone. Until the 2026-11-08 deep review (F14) both ran, so one eat
	-- took two afflictions (ataxia_knownCureV3, ataxia/001_Miscellaneous_Aff_Tracking_Methods).
	-- Mercury (the homunculus, 444) goes BEFORE the random cure: the known-cure line compares the
	-- branches with the copy taken just after it, so an erase between the two made every known line
	-- on a target with mercury miss, and the eat took two afflictions again. Mercury is in no cure
	-- table, so the random cure weighs the same afflictions either way; the plant timer below still
	-- reads whether it was there.
	local hadMercury = tAffs.mercury
	if hadMercury then erAff("mercury") end
	if ataxia_randomCureV3 then
		ataxia_randomCureV3("goldenseal", matches[2], function() targetAteWrapper("goldenseal") end)
	else
		targetAteWrapper("goldenseal")
	end
  if passiveFailsafe then restorePassiveCure() end
	-- (Used to erAff("shadowmadness") on EVERY goldenseal eat, whatever was
	-- cured. shadowmadness is now in curingTable.goldenseal, so the V3 cure
	-- above weighs it with the rest -- v4.7.372, deep review.)

	tBals.plant = false
  if tBals.timers.plant then killTimer(tBals.timers.plant) end
	if hadMercury then
		tBals.timers.plant = tempTimer(1.9, [[tBals.plant = true; tBals.timers.plant = nil]])
	else
		tBals.timers.plant = tempTimer(1.3, [[tBals.plant = true; tBals.timers.plant = nil]])
	end
	targetIshere = true
  predictBal("herb", 1.55)	
end

	selectString(line, 1)
	fg("PeachPuff")
	resetFormat()