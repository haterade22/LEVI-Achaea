--[[mudlet
type: trigger
name: Aeon Hit
hierarchy:
- Levi_Ataxia
- For Levi
- leviticus
- Ataxia
- Combat/Aff Tracking
- Add Afflictions
- Classes Other
- Misc Stuff
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
- pattern: ^(\w+) seems to be moving in slow motion suddenly.$
  type: 1
- pattern: ^Standing the Aeon on your open palm, you blow it lightly at (\w+) and watch as it seems to slow \w+ movement through
    the time stream.$
  type: 1
]]--

if isTargeted(matches[2]) then
	tarAffed("aeon")
	if applyAffV3 then applyAffV3("aeon") end
  send("pt "..target:upper().." AEONED!")
end