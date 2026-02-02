--[[mudlet
type: trigger
name: MASO DIZZY
hierarchy:
- Levi_Ataxia
- For Levi
- leviticus
- Ataxia
- Combat/Aff Tracking
- Add Afflictions
- Classes A-J
- Apostate
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
- pattern: ^(\w+) clutches at (her|his) head as the screeching of the bloodworms rises to a diabolical cacophony.$
  type: 1
]]--

if isTargeted(matches[2]) then
	tarAffed("masochism")
	if applyAffV3 then applyAffV3("masochism") end
  	tarAffed("dizziness")
  	if applyAffV3 then applyAffV3("dizziness") end
end

