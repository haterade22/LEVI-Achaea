--[[mudlet
type: trigger
name: Bleed Curse
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
- pattern: ^Blood begins to flow from (\w+)'s pores.$
  type: 1
]]--

if tAffs.bleed == nil then tAffs.bleed = 0 end
tAffs.bleed = tAffs.bleed + 50
selectString(line,1)
if tAffs.bleed < 200 then
  --don't colour it
elseif tAffs.bleed < 400 then
  fg("NavajoWhite")
elseif tAffs.bleed < 600 then
  fg("orange")
else
  fg("firebrick")
end
deselect()
resetFormat()