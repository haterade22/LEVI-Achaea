--[[mudlet
type: trigger
name: Incoming Attack Tracker
hierarchy:
- Levi_Ataxia
- For Levi
- leviticus
- LeviAtax
- Leviticus
- slc
- Tekura Limb Attacks
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
- pattern: ^(\w+) launches a powerful uppercut at you.$
  type: 1
- pattern: ^(\w+) unleashes a powerful hook towards you.$
  type: 1
- pattern: ^(\w+) forms a spear hand and stabs out at you.$
  type: 1
- pattern: ^(\w+) balls up one fist and hammerfists you.$
  type: 1
- pattern: ^(\w+) pumps out at you with a powerful side kick\.$
  type: 1
- pattern: ^(\w+) lets fly at you with a snap kick\.$
  type: 1
- pattern: ^(\w+) hurls \w+ towards you with a lightning-fast moon kick\.$
  type: 1
- pattern: ^(\w+) spins into the air and throws a whirlwind kick towards you\.$
  type: 1
- pattern: ^(\w+) kicks his leg high and scythes downwards at you\.$
  type: 1
- pattern: ^(\w+) throws \w+ palm towards your face\.$
  type: 1
]]--

clumsiness_lastAttacker = matches[2]
