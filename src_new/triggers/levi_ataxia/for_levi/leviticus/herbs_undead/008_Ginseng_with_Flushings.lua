--[[mudlet
type: trigger
name: Ginseng with Flushings
hierarchy:
- Levi_Ataxia
- For Levi
- leviticus
- Ataxia
- Herbs Undead
attributes:
  isActive: 'no'
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

if isTargeted(multimatches[1][2]) then
tdeliverance = false
  predictBal("herb", 1.55)	
	if anorexiaFailsafe then
		tAffs[lastFocus] = true
		ataxiaEcho("Backtracked anorexia being cured with last focus.")
		anorexiaFailsafe = nil
		lastFocus = nil
	end
  if passiveFailsafe then restorePassiveCure() end
	flushingsProc()

	selectString(line, 1)
	fg("NavajoWhite")
	resetFormat()

	tBals.plant = false
  if tBals.timers.plant then killTimer(tBals.timers.plant) end
	if tAffs.mercury then
		tAffs.mercury = false
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