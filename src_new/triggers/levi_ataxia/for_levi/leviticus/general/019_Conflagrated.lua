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
    if applyAffV3 then applyAffV3("conflagration") end
    if partyrelay and not ataxia.afflictions.aeon then send("pt " ..target.. ": conflagration") end
    tburns = tburns or 2
  end

tfirelash = false