--[[mudlet
type: trigger
name: Ginseng with Flushings
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
- pattern: ^(\w+) eats a (ginseng root|ferrum flake).$
  type: 1
- pattern: '1'
  type: 5
- pattern: ^Blood begins to run from the pores of (\w+).$
  type: 1
]]--

-- 007_Ginseng reads the same eat line and has charged the eat by the time this line prints, unless
-- the target is still part of a name (it compares the exact name). Read before isTargeted, which
-- completes the name.
local eater = multimatches[1][2]
local chargedBy007 = target == eater

if isTargeted(eater) then
tdeliverance = false
  predictBal("herb", 1.55)	
	if anorexiaFailsafe then
		tAffs[lastFocus] = true
		ataxiaEcho("Backtracked anorexia being cured with last focus.")
		anorexiaFailsafe = nil
		lastFocus = nil
	end
  if passiveFailsafe then restorePassiveCure() end
	-- This line cures nothing. With flushings up the eat takes ONE other affliction and the line
	-- follows it; flushings is still on the next prompt in all five first-person rows
	-- (2026-11-01_claes_runewarden-vs-pariah_loss_Vr.NkCGD.txt:853-857, _4c_SeyaA.txt:1869-1873,
	-- 1974-1978, 2415-2421, _WKuEakBZ.txt:1126-1131). No log holds this third-person form.
	-- This body used to charge the eat a second time (targetAteWrapper, on top of 007) and then
	-- erase a third affliction (flushingsProc), so one eat took up to three (2026-11-08 deep review).
	if not chargedBy007 then
		if ataxia_randomCureV3 then
			ataxia_randomCureV3("ginseng", eater, function() targetAteWrapper("ginseng") end)
		else
			targetAteWrapper("ginseng")
		end
	end

	selectString(line, 1)
	fg("NavajoWhite")
	resetFormat()

	tBals.plant = false
  if tBals.timers.plant then killTimer(tBals.timers.plant) end
	if tAffs.mercury then
		erAff("mercury")
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