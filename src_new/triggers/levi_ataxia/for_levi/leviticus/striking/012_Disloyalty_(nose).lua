--[[mudlet
type: trigger
name: Disloyalty (nose)
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
- pattern: ^With the heel of your palm, you send a pulverising blow at (\w+)'s nose.$
  type: 1
]]--

if isTargeted(matches[2]) then
		tarAffed("disloyalty")
		if applyAffV3 then applyAffV3("disloyalty") end
  if not ataxia.afflictions.aeon and partyrelay then
  send("pt " ..target..": disloyalty")
end
end