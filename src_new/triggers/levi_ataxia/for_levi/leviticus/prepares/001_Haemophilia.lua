--[[mudlet
type: trigger
name: Haemophilia
hierarchy:
- Levi_Ataxia
- For Levi
- leviticus
- Ataxia
- Combat/Aff Tracking
- Add Afflictions
- Classes K-S
- Psion
- Prepares
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
- pattern: ^The spikes adorning your \w+ tear bloody furrows in the flesh of (\w+).$
  type: 1
- pattern: ^Your blade tears into (\w+), a spray of crimson exploding from the wound as your weapon strikes bone.$
  type: 1
]]--

if isTargeted(matches[2]) then
	tarAffed("haemophilia")
	if applyAffV3 then applyAffV3("haemophilia") end
end