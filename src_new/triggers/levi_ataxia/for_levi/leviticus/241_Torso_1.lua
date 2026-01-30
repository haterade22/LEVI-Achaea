--[[mudlet
type: trigger
name: Torso
hierarchy:
- Levi_Ataxia
- For Levi
- leviticus
- LeviAtax
- Leviticus
- Runie
- RuneWarden
- SNB
- Parry
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
conditonLineDelta: 1
mStayOpen: 0
mCommand: ''
packageName: ''
mFgColor: '#ff0000'
mBgColor: '#ffff00'
mSoundFile: ''
colorTriggerFgColor: '#000000'
colorTriggerBgColor: '#000000'
patterns:
- pattern: ^You slice into the torso of (\w+) with Valafar, a crimson-tinged hellforged longsword.$
  type: 1
- pattern: '1'
  type: 5
- pattern: ^(\w+) parries the attack with a deft manoeuvre.$
  type: 1
]]--

Deadeyes1 = nil
svenom1 = ""

tparrying = "torso"
send("pt " ..target.. ": PARRYING " ..tparrying)

erAff("nausea")
tAffs.nausea = false

