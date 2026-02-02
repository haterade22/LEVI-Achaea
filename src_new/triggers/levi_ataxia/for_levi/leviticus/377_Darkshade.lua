--[[mudlet
type: trigger
name: Darkshade
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
- pattern: ^(\w+) stiffens suddenly, his features a masque frozen in agony\.$
  type: 1
- pattern: ^(\w+) lets out a piercing scream, as if wounded by the very sunlight\.$
  type: 1
]]--

if isTargeted(matches[2]) then
	tarAffed("darkshade")
	if applyAffV3 then applyAffV3("darkshade") end
  confirmAffV2("darkshade")
end