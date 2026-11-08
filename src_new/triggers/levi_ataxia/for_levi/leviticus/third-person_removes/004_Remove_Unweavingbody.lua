--[[mudlet
type: trigger
name: Remove Unweavingbody
hierarchy:
- Levi_Ataxia
- For Levi
- leviticus
- Ataxia
- Combat/Aff Tracking
- Remove Afflictions
- Groups
- Third-Person Removes
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
- pattern: ^(\w+) suddenly seems much more vital.$
  type: 1
]]--

if isTargeted(matches[2]) then
  if ataxiaTemp.randomCure and ataxiaTemp.randomCure > 0 then ataxiaTemp.randomCure = ataxiaTemp.randomCure - 1 end
	-- After the target's ginseng/ferrum eat this line names the cure, so it replaces the eat's random
	-- cure (herbs/007, ataxia_knownCureV3), and the eat counts once. With no such eat just before, it
	-- only erases.
	if ataxia_knownCureV3 then ataxia_knownCureV3("ginseng", matches[2], "unweavingbody") end
	erAff("unweavingbody")
	erAff("criticalbody")
	targetIshere = true
end

bodyinvert = false
inverted = false
