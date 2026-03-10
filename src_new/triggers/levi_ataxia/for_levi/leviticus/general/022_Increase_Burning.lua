--[[mudlet
type: trigger
name: Increase Burning
hierarchy:
- Levi_Ataxia
- For Levi
- leviticus
- LeviAtax
- Leviticus
- Mage
- General
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
- pattern: ^You fan the heat of \w+'s body into consuming flame\.$
  type: 1
]]--

magi.offense = magi.offense or {}
magi.offense.state = magi.offense.state or {}
magi.offense.state.burns = math.min((magi.offense.state.burns or 0) + 1, 5)
tburns = magi.offense.state.burns -- backward compat
tarAffed("burning")