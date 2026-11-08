--[[mudlet
type: trigger
name: Remove Rebbies
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
- pattern: ^The skin of (\w+) ceases secreting slime.$
  type: 1
]]--

if isTargeted(matches[2]) then
  if ataxiaTemp.randomCure and ataxiaTemp.randomCure > 0 then ataxiaTemp.randomCure = ataxiaTemp.randomCure - 1 end
	-- After the target's kelp/aurum eat this line names the cure, so it replaces the eat's random
	-- cure (herbs/003, ataxia_knownCureV3), and the eat counts once. The line also follows a tree
	-- (first person, 2026-11-01_claes_runewarden-vs-pariah_loss_4c_SeyaA.txt:521-522); with no such
	-- eat just before, it only erases.
	if ataxia_knownCureV3 then ataxia_knownCureV3("kelp", matches[2], "rebbies") end
	erAff("rebbies")
	targetIshere = true
end
