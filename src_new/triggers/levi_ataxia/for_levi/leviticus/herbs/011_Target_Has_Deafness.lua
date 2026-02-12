--[[mudlet
type: trigger
name: Target Has Deafness
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
- pattern: ^(\w+) eats a (hawthorn berry|calamine crystal).$
  type: 1
- pattern: ^A brief look of concentration crosses the face of (\w+).$
  type: 1
]]--

if isTargeted(matches[2]) and matches[1]:find("eats") then
tdeliverance = false
	-- Eating proves no anorexia (anorexia blocks eating)
	erAff("anorexia")
	if removeAffV3 then removeAffV3("anorexia") end
  predictBal("herb", 1.55)
	selectString(line, 1)
	fg("NavajoWhite")
	resetFormat()
	tBals.plant = false
  if tBals.timers.plant then killTimer(tBals.timers.plant) end
	if tAffs.mercury then
		tAffs.mercury = false
		if removeAffV3 then removeAffV3("mercury") end
		tBals.timers.plant = tempTimer(1.9, [[tBals.plant = true; tBals.timers.plant = nil]])
	else
		tBals.timers.plant = tempTimer(1.3, [[tBals.plant = true; tBals.timers.plant = nil]])
	end

	-- Calamine cures deafness - clear it immediately (V1 and V2)
	tAffs.deafness = false
	if removeAffV3 then removeAffV3("deafness") end
	if tAffsV2 then tAffsV2.deafness = 0 end
	tempTimer(2.5, [[tAffs.deafness = true; if tAffsV2 then tAffsV2.deafness = 0 end; if applyAffV3 then applyAffV3("deafness") end]])
	targetIshere = true
elseif isTargeted(matches[2]) and matches[1]:find("concentration") then
	selectString(line, 1)
	fg("NavajoWhite")
	resetFormat()

	tempTimer(5, [[tAffs.deafness = true; if applyAffV3 then applyAffV3("deafness") end]])
	targetIshere = true
end