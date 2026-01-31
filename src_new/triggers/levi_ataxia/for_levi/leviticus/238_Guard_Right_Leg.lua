--[[mudlet
type: trigger
name: Guard Right Leg
hierarchy:
- Levi_Ataxia
- For Levi
- leviticus
- LeviAtax
- Leviticus
- Bard
attributes:
  isActive: 'yes'
  isFolder: 'no'
  isTempTrigger: 'no'
  isMultiline: 'yes'
  isPerlSlashGOption: 'no'
  isColorizerTrigger: 'no'
  isFilterTrigger: 'no'
  isSoundTrigger: 'no'
  isColorTrigger: 'no'
  isColorTriggerFg: 'no'
  isColorTriggerBg: 'no'
triggerType: 0
conditonLineDelta: 2
mStayOpen: 0
mCommand: ''
packageName: ''
mFgColor: '#ff0000'
mBgColor: '#ffff00'
mSoundFile: ''
colorTriggerFgColor: '#000000'
colorTriggerBgColor: '#000000'
patterns:
- pattern: ^You viciously jab a (\w+)'s right leg into a Soulpiercer.$
  type: 1
- pattern: ^(\w+) moves into your attack, knocking your blow aside before viciously countering with a strike to your head\.$
  type: 1
]]--

tparrying = "right leg"


send("pt " ..target..": Parrying " ..tparrying)
Deadeyes1 = nil


