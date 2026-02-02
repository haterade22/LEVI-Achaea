--[[mudlet
type: trigger
name: Temperance
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
- pattern: ^You direct your will against the temperance elixir which protects (\w+) and it burns away\.$
  type: 1
]]--

targetlostfrost = true
tempTimer(17, [[targetlostfrost = false; erAff("notemperance"); if removeAffV3 then removeAffV3("notemperance") end]])
tarAffed("notemperance")
if applyAffV3 then applyAffV3("notemperance") end