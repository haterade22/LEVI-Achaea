--[[mudlet
type: trigger
name: Recklessness (groin)
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
- pattern: ^Targeting a vulnerable point, you lash out at (\w+)'s groin with a calculated strike.$
  type: 1
]]--

if isTargeted(matches[2]) then
		tarAffed("recklessness")
		if applyAffV3 then applyAffV3("recklessness") end
  if not ataxia.afflictions.aeon and partyrelay then
  send("pt " ..target..": recklessness")
end
end