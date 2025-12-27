--[[mudlet
type: trigger
name: Focus Speed
hierarchy:
- Levi_Ataxia
- For Levi
- leviticus
- Ataxia
- Combat/Aff Tracking
- Misc Tracking
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
- pattern: Channeling the fury of battle, you prepare to unleash a brutally swift stroke against your foe.
  type: 3
- pattern: You shift your stance, poising yourself for a precise strike against your foe.
  type: 3
]]--

if ataxiaBasher.enabled then
	deleteFull()
else
	selectString(line, 1)
	fg("NavajoWhite")
	deselect()
  
  
  if line:find("swift stroke") then
    ataxiaTemp.thfocus = "speed"
  else
    ataxiaTemp.thfocus = "precision"
  end
  tempTimer(2.8, [[ ataxiaTemp.thfocus = nil ]])
end