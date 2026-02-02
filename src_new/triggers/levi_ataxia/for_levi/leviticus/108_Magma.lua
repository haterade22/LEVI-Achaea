--[[mudlet
type: trigger
name: Magma
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
- pattern: ^You weave fire and earth and bubbling magma boils into existence to wash over (\w+) in a skin-melting tide\.$
  type: 1
]]--

if target == matches[2] then
    tarAffed("scalded")
    if applyAffV3 then applyAffV3("scalded") end
    if partyrelay and not ataxia.afflictions.aeon then send("pt " ..target.. ": Scalded") end
  end
tempTimer(20, [[erAff("scalded"); if removeAffV3 then removeAffV3("scalded") end]])
