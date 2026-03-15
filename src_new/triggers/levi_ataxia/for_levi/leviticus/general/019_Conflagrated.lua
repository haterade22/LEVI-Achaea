--[[mudlet
type: trigger
name: Conflagrated
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
- pattern: ^You bend your will upon (\w+), and command that (\w+) burn\.$
  type: 1
]]--

if target == matches[2] then
    tarAffed("conflagration")
    magi.offense.state.conflagrated = true
    magi.offense.state.burns = math.min((magi.offense.state.burns or 0) + 2, 5)
    tburns = magi.offense.state.burns
    magi.offense.ptRelay(target .. ": Conflagrated! (burns:" .. magi.offense.state.burns .. ")")
  end

tfirelash = false