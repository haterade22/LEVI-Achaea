--[[mudlet
type: trigger
name: Crescendo Building 2 - 4
hierarchy:
- Levi_Ataxia
- For Levi
- leviticus
- Ataxia
- Combat/Aff Tracking
- Add Afflictions
- Classes A-J
- Bard
- Bard Rework
- Blade Dance
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
- pattern: ^You sense your grand performance drawing ever closer to a conclusion about \w+\.$
  type: 1
]]--

if tAffs.crescendo == 1 then
    tAffs.crescendo = 2
  elseif tAffs.crescendo == 2 then
    tAffs.crescendo = 3
  elseif tAffs.crescendo == 3 then
    tAffs.crescendo = 4
  elseif tAffs.crescendo == 4 then
    tAffs.crescendo = 5
  elseif tAffs.crescendo >= 5 then
    tAffs.crescendo = 5
  end
  
 bladefinale = false