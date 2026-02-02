--[[mudlet
type: trigger
name: Hamstring Fade
hierarchy:
- Levi_Ataxia
- For Levi
- leviticus
- Ataxia
- Combat/Aff Tracking
- Add Afflictions
- Classes A-J
- Blademaster
- Striking
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
- pattern: ^(\w+) seems able to move more freely all of a sudden.$
  type: 1
]]--

if isTargeted(matches[2]) then
	selectString(line,1)
	fg("tomato")
	resetFormat()
	erAff("hamstring")
	if removeAffV3 then removeAffV3("hamstring") end
	if hamstringTimer then killTimer(hamstringTimer) end

if not ataxia.afflictions.aeon and partyrelay then
  send("pt " ..target..": ")
end
end