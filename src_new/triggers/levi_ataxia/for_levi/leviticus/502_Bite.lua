--[[mudlet
type: trigger
name: Bite
hierarchy:
- Levi_Ataxia
- For Levi
- leviticus
- Ataxia
- Combat/Aff Tracking
- Add Afflictions
- Classes K-S
- Serpent
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
- pattern: ^You sink your fangs into (\w+), injecting just the proper amount of (\w+).$
  type: 1
]]--

if isTargeted(matches[2]) then
	if matches[3] ~= "loki" and matches[3] ~= "camus" then
		tarAffed(venom_to_aff(matches[3]))
		if applyAffV3 then applyAffV3(venom_to_aff(matches[3])) end
	end
end