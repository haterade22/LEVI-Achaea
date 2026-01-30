--[[mudlet
type: trigger
name: Jinx Stopped
hierarchy:
- Levi_Ataxia
- For Levi
- leviticus
- Ataxia
- Combat/Aff Tracking
- Add Afflictions
- Classes K-S
- Shaman
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
- pattern: ^(\w+) is protected from your (\w+) curse by a ward.$
  type: 1
]]--

erAff("paralysis")
selectString(line,1)
fg("tomato")
resetFormat()
tAffs.curseward = true

local prevented_aff = curseConvert(matches[2])
erAff(prevented_aff)

tAffs.bleed = tAffs.bleed - 40
if tAffs.bleed < 0 then tAffs.bleed = nil end