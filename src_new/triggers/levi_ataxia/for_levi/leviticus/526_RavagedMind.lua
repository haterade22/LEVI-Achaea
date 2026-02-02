--[[mudlet
type: trigger
name: RavagedMind
hierarchy:
- Levi_Ataxia
- For Levi
- leviticus
- Ataxia
- Combat/Aff Tracking
- Add Afflictions
- Classes K-S
- Psion
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
- pattern: ^Bringing your formidable mental facilities to bear against (\w+), you summon up and hurl a terrible unfocussed
    blast of psionic might to ravage \w+ mind\.$
  type: 1
- pattern: ^\w+ gives a great shout of exertion and (\w+) staggers, clutching at \w+ head as blood drips from \w+ ears\.$
  type: 1
]]--

if isTargeted(matches[2]) then
	tarAffed("mindravaged")
	if applyAffV3 then applyAffV3("mindravaged") end
end



ataxia_boxEcho("RAVAGED||RAVAGED||RAVAGED", "black:orange")