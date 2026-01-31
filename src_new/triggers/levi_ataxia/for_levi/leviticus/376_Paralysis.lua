--[[mudlet
type: trigger
name: Paralysis
hierarchy:
- Levi_Ataxia
- For Levi
- leviticus
- Ataxia
- Combat/Aff Tracking
- Add Afflictions
- Third Person
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
- pattern: ^Horror overcomes (\w+)'s face as \w+ body stiffens into paralysis.$
  type: 1
- pattern: ^(\w+) stiffens suddenly, \w+ features a masque frozen in agony.$
  type: 1
- pattern: ^(\w+)'s body stiffens rapidly with paralysis\.$
  type: 1
- pattern: ^(?:\w+) recites an epic tale of the heroism of Nicator to (\w+)\.$
  type: 1
- pattern: ^Lunging to the side, (?:\w+) brings (?:\w+) shield around to smash into the spine of (\w+).
  type: 1
- pattern: ^The body of (\w+) locks in paralysis as \w+ directs a short burst of arcane power in \w+ direction.$
  type: 1
- pattern: ^The bees sting (\w+) into paralysis.$
  type: 1
]]--

if isTargeted(matches[2]) then
	tarAffedConfirmed("paralysis")

	-- V3 integration: collapse branches (proves paralysis present)
	if onTargetParalysisBlockV3 then onTargetParalysisBlockV3() end
end