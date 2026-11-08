--[[mudlet
type: trigger
name: Ginseng
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
- pattern: ^(\w+) eats a (ginseng root|ferrum flake).$
  type: 1
]]--


if target == matches[2] then
tdeliverance = false
	if anorexiaFailsafe then
		tAffs[lastFocus] = true
		ataxiaEcho("Backtracked anorexia being cured with last focus.")
		anorexiaFailsafe = nil
		lastFocus = nil
	end
  if passiveFailsafe then restorePassiveCure() end

	-- The eat is charged now as a random cure. When the next line names the cure ("X suddenly seems
	-- much more vital." -> unweavingbody, third-person_removes/004), that trigger puts the branches
	-- back and charges the named one alone (ataxia_knownCureV3, ataxia/001), so one eat takes one
	-- affliction. Mercury goes BEFORE the random cure, as in 002_Goldenseal: an erase between it and
	-- the known-cure line makes the comparison of the branches miss. Mercury is in no cure table, so
	-- the random cure weighs the same afflictions either way.
	local hadMercury = tAffs.mercury
	if hadMercury then erAff("mercury") end
	if ataxia_randomCureV3 then
		ataxia_randomCureV3("ginseng", matches[2], function() targetAteWrapper("ginseng") end)
	else
		targetAteWrapper("ginseng")
	end
	-- Track for adaptive serpent offense
	if serpent and serpent.trackCure then serpent.trackCure("ginseng") end

	selectString(line, 1)
	fg("NavajoWhite")
	resetFormat()

	tBals.plant = false
  if tBals.timers.plant then killTimer(tBals.timers.plant) end
	if hadMercury then
		tBals.timers.plant = tempTimer(1.9, [[tBals.plant = true; tBals.timers.plant = nil]])
	else
		tBals.timers.plant = tempTimer(1.3, [[tBals.plant = true; tBals.timers.plant = nil]])
	end

	if strikingHigh and not strikeHighTimer then
		strikingHigh = nil
		strikeHighTimer = tempTimer(1.15, [[
			if ataxia.vitals.class == 4 and not haveAff("rebounding") then
				send("shieldstrike "..target.." high")
			end 	
			strikeHighTimer = nil
		]])
	end	
	targetIshere = true
end
selectString(line, 1)
fg("green")
resetFormat()

