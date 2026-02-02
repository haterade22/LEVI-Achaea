--[[mudlet
type: trigger
name: Addiction/Scarab
hierarchy:
- Levi_Ataxia
- For Levi
- leviticus
- Ataxia
- Combat/Aff Tracking
- Add Afflictions
- Classes K-S
- Pariah
- Logographs
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
- pattern: ^Something undulates grotesquely within the stomach of (.+)\, and a ravenous gleam enters \w+ eyes.$
  type: 1
- pattern: ^Something writhes within the stomach of (.+)\, \w+ face contorting in a strangely hungry expression.$
  type: 1
- pattern: ^As the logograph becomes fully formed it leaps from the air to (.+)\, ethereal legs scrabbling as it burrows into
    \w+ body and vanishes without a trace.$
  type: 1
]]--

if type(target) == "string" and isTargeted(matches[2]) then
	tarAffed("addiction")
	if applyAffV3 then applyAffV3("addiction") end
end

if ataxiaBasher.enabled then
  if not ataxiaBasher.manual then
    deleteFull()
  end
end