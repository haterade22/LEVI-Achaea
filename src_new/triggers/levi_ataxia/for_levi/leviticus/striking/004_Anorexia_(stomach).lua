--[[mudlet
type: trigger
name: Anorexia (stomach)
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
- pattern: ^You aim a measured blow at (\w+)'s stomach, feeling muscles clench beneath your fist.$
  type: 1
]]--

if isTargeted(matches[2]) then
		tarAffed("anorexia")
		if applyAffV3 then applyAffV3("anorexia") end

if not ataxia.afflictions.aeon and partyrelay then
  send("pt " ..target..": anorexia")
end
end