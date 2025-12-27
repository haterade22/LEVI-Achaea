--[[mudlet
type: trigger
name: Conviction Line
hierarchy:
- Levi_Ataxia
- For Levi
- leviticus
- Ataxia
- Combat/Aff Tracking
- Add Afflictions
- Classes K-S
- Priest
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
- pattern: ^Your spirit surges with (\d+)\% holy conviction.$
  type: 1
]]--

local x = tonumber(matches[2])
ataxiaTemp.conviction = x
selectString(matches[2],1)
if x > 75 then
	fg("black")
	bg("goldenrod")
elseif x >= 50 then
	fg("green")
elseif x >= 25 then
	fg("red")
else
	fg("NavajoWhite")
end
deselect()

