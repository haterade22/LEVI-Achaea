--[[mudlet
type: trigger
name: Hallucinations (eyes)
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
- pattern: ^With pinpoint strikes to (\w+)'s sockets, you burst blood vessels in \w+ eyes, causing them to run red.$
  type: 1
]]--

if isTargeted(matches[2]) then
		tarAffed("hallucinations")
		if applyAffV3 then applyAffV3("hallucinations") end
  if not ataxia.afflictions.aeon and partyrelay then
  send("pt " ..target..": hallucinations")
end
end