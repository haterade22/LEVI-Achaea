--[[mudlet
type: trigger
name: Envenomed
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
- pattern: ^You rub some (\w+) on (.+).$
  type: 1
]]--

if ataxia.vitals.knight ~= "Dual Cutting" then
ataxiaTemp.hitCount = 0
if not affs_to_colour then populate_aff_colours() end
local aff = venom_to_aff(matches[2])
envenomList = envenomList or {}

if ataxiaTemp.hitCount == 0 then
  table.insert(envenomList,1,aff)
 
  ataxiaTemp.hitCount = 0
  end  
end
deleteFull()
