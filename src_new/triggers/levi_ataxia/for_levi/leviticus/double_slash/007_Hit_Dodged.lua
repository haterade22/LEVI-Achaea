--[[mudlet
type: trigger
name: Hit Dodged
hierarchy:
- Levi_Ataxia
- For Levi
- leviticus
- Ataxia
- Combat/Aff Tracking
- Add Afflictions
- Classes K-S
- Double Slash
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
- pattern: ^(\w+) twists \w+ body out of harm\'s way\.$
  type: 1
- pattern: ^(\w+) quickly jumps back, avoiding the attack.$
  type: 1
- pattern: ^(\w+) dodges nimbly out of the way.$
  type: 1
- pattern: ^A reflection of (\w+) blinks out of existence.$
  type: 1
- pattern: The attack rebounds back onto you!
  type: 3
- pattern: ^You lash out at (\w+) with (.+), but miss\.$
  type: 1
]]--

ataxiaTemp.hitCount = ataxiaTemp.hitCount + 1
