--[[mudlet
type: trigger
name: Target has blindness
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
- pattern: ^(\w+) eats some bayberry bark.$
  type: 1
- pattern: ^(\w+) eats an arsenic pellet.$
  type: 1
- pattern: ^(\w+) is blind; your lethal gaze would have no hold over \w+.$
  type: 1
]]--

if isTargeted(matches[2]) and tBals.plant and matches[1]:find("eats") then
tdeliverance = false
	-- Eating proves no anorexia (anorexia blocks eating)
	erAff("anorexia")
	if removeAffV3 then removeAffV3("anorexia") end
  predictBal("herb", 1.55)
	selectString(line, 1)
	fg("NavajoWhite")
	resetFormat()

	tAffs.blindness = true
	if applyAffV3 then applyAffV3("blindness") end
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
elseif isTargeted(matches[2]) and matches[1]:find("is blind") then
	selectString(line, 1)
	fg("NavajoWhite")
	resetFormat()

	tAffs.blindness = true
	if applyAffV3 then applyAffV3("blindness") end
	targetIshere = true
end
