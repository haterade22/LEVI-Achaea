--[[mudlet
type: trigger
name: Truewrack
hierarchy:
- Levi_Ataxia
- For Levi
- leviticus
- Ataxia
- Combat/Aff Tracking
- Add Afflictions
- Classes A-J
- Alchemist
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
- pattern: ^You send ripples throughout \w+'s body, wracking \w+ \w+ and \w+ humours.$
  type: 1
- pattern: ^You send ripples throughout the body of \w+, as you wrack \w+ \w+ humour twice.$
  type: 1
]]--

tarAffed(ataxiaTemp.truewrackOne, ataxiaTemp.truewrackTwo)
ataxiaTemp.truewrackOne = nil
ataxiaTemp.truewrackTwo = nil