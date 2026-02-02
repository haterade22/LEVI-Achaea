--[[mudlet
type: trigger
name: Calcify Head Finish
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
- pattern: ^A look of pain comes over (\w+) and the bones seem to shift beneath the skin stretched across \w+ skull.$
  type: 1
]]--

if target == matches[2] then
  lb[target].hits["head"] = lb[target].hits["head"] + 100.01
  erAff("Calcifiedskull")
  if removeAffV3 then removeAffV3("Calcifiedskull") end
end
  magi.calcifying_head = false
  