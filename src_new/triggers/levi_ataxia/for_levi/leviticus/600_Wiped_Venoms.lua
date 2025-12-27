--[[mudlet
type: trigger
name: Wiped Venoms
hierarchy:
- Levi_Ataxia
- For Levi
- leviticus
- Ataxia
- Combat/Aff Tracking
- Misc Tracking
attributes:
  isActive: 'no'
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
- pattern: ^Being careful not to poison yourself, you wipe off all the venoms from (.+).$
  type: 1
- pattern: There are no venoms on that item at present.
  type: 3
]]--

envenomList = {}

local knights = {"Infernal", "Paladin", "Runewarden", "Unnamable"}
if table.contains(knights, ataxiaTemp.class) and ataxia.vitals.knight == "Dual Cutting" then
  envenomListTwo = {}
end
deleteFull()
needwipe = false