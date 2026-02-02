--[[mudlet
type: trigger
name: Bellwort/Cuprum
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
- pattern: ^(\w+) eats a (cuprum flake|bellwort flower).$
  type: 1
- pattern: '1'
  type: 5
- pattern: (.*)
  type: 1
]]--

local name = multimatches[1][2]
if isTargeted(multimatches[1][2]) then
tdeliverance = false
	if anorexiaFailsafe then
		tAffs[lastFocus] = true
		ataxiaEcho("Backtracked anorexia being cured with last focus.")
		anorexiaFailsafe = nil
		lastFocus = nil
	end
  if passiveFailsafe then restorePassiveCure() end
	
	if multimatches[3][1] == name .. " gives a sigh of relief." then
		erAff("retribution")
    erAff("earworm")
	elseif multimatches[3][1] == name .. " shakes his head and a look of clarity returns to his eyes."
		or multimatches[3][1] == name .. " shakes her head and a look of clarity returns to her eyes." then
			erAff("lovers")
	else
		targetAteWrapper("bellwort")
		if onHerbCureV3 then onHerbCureV3("bellwort") end
	end
	tBals.plant = false
  if tBals.timers.plant then killTimer(tBals.timers.plant) end
	if tAffs.mercury then
		tAffs.mercury = false
		if removeAffV3 then removeAffV3("mercury") end
		tBals.timers.plant = tempTimer(1.9, [[tBals.plant = true; tBals.timers.plant = nil]])
	else
		tBals.timers.plant = tempTimer(1.3, [[tBals.plant = true; tBals.timers.plant = nil]])
	end
	targetIshere = true
end