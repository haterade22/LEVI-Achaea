--[[mudlet
type: trigger
name: Attunements
hierarchy:
- Levi_Ataxia
- For Levi
- leviticus
- Ataxia
- Spiritlore System
- Bindings
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
- pattern: ^You have attuned yourself to (['\w]+), The \w+.$
  type: 1
- pattern: ^You have attuned yourself to (['\w]+), The \w+ and (['\w]+), The \w+.$
  type: 1
- pattern: ^You have attuned yourself to (['\w]+), The \w+, (['\w]+), The \w+, and (['\w]+), The \w+.$
  type: 1
]]--

if matches[4] then
	shaman.spiritlore.attunements = { matches[2], matches[3], matches[4] }
elseif matches[3] then
	shaman.spiritlore.attunements = { matches[2], matches[3] }
else
	shaman.spiritlore.attunements = { matches[2] }
end