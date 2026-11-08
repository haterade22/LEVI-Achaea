--[[mudlet
type: trigger
name: Focus (UNK)
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
- pattern: ^A look of extreme focus crosses the face of (\w+)\.$
  type: 1
]]--

if isTargeted(matches[2]) and tBals.focus then
	-- V3 owns the focus cure when it is loaded: onTargetFocusV3 drops the
	-- branches that hold impatience (a focus proves it absent) and removes ONE
	-- focus-curable aff -- and it refuses an illusion focus (off focus balance,
	-- or impatience confirmed). The unconditional erAff + tFocused below used
	-- to run as well, overriding those guards and removing a SECOND aff from
	-- every branch (v4.7.372, deep review). They remain the non-V3 path.
	-- This trigger owns the focus. 399 (the same line, then the next) only reads that next line:
	-- when it names the cure (lovers), ataxia_knownCureV3 puts back the branches kept here, so the
	-- focus counts once. 399 used to repeat all of this behind `tBals.focus`, which is false by the
	-- time it runs (set below, a line earlier), so its Serpent count never ran (2026-11-08 deep
	-- review, F43; 68 focus lines in the six Serpent logs, kb/raw/logs/ours/2026-11-07_164635_Saibel.log:372).
	if onTargetFocusV3 then
		if ataxia_randomCureV3 then
			ataxia_randomCureV3("focus", matches[2], onTargetFocusV3)
		else
			onTargetFocusV3()
		end
	else
		erAff("impatience")
		tFocused()
	end
	-- Track for adaptive serpent offense (moved here from 399, F43). The focus count itself is only
	-- shown (ekstatus), but every trackCure call also rolls the 6 s window (serpent/002
	-- serpent.trackCure), so a focus can now clear an expired ginseng count that determineStrategy reads.
	if serpent and serpent.trackCure then serpent.trackCure("focus") end
	-- Inside the guard. This block ran for anyone's focus line, so a bystander's focus
	-- put the TARGET's clock down, and the gate above then refused the target's real cure.
	tBals.focus = false
	tBals.focusUsedAt = getEpoch()

  if tBals.timers.focus then killTimer(tBals.timers.focus) end
	if haveAff("shadowmadness") then
		-- Measured 4.82-4.99 s, n=6 (kb/mechanics/foundations.md). A 5 s wait refused real cures.
		tBals.timers.focus = tempTimer(4.8, [[tBals.focus = true; tBals.timers.focus = nil]])
	else
		tBals.timers.focus = tempTimer(2, [[tBals.focus = true; tBals.timers.focus = nil]])
	end
	targetIshere = true
end
