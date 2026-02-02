--[[mudlet
type: trigger
name: Thunderclap (nodeaf)
hierarchy:
- Levi_Ataxia
- For Levi
- leviticus
- Ataxia
- Combat/Aff Tracking
- Add Afflictions
- Affs Post Queue - Gated
- Classes K-S
- Sylvan
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
- pattern: ^Channeling large quantities of arcane power through your air channel, you direct a localised explosion of pure
    sound at (\w+), restoring \w+ hearing.$
  type: 1
]]--

if isTargeted(matches[2]) then
	if sylvan_overcharge then
		tarAffed("paralysis")
		if applyAffV3 then applyAffV3("paralysis") end
	end
	tAffs.deafness = false
	if removeAffV3 then removeAffV3("deafness") end
end