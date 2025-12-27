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

if isTargeted(matches[2]) and tBals.plant and matches[1]:find("eats") then
tdeliverance = false
  predictBal("herb", 1.55)	
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

	tempTimer(2.5, [[tAffs.deafness = true]])
	targetIshere = true
elseif isTargeted(matches[2]) and matches[1]:find("concentration") then
	selectString(line, 1)
	fg("NavajoWhite")
	resetFormat()

	tempTimer(5, [[tAffs.deafness = true]])
	targetIshere = true
end