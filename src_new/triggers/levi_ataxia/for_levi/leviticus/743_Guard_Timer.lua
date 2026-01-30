--[[mudlet
type: trigger
name: Guard Timer
hierarchy:
- Levi_Ataxia
- For Levi
- leviticus
- Ataxia
- Misc Triggers
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
- pattern: You close your eyes and focus all of your attention on summoning a guard to your location.
  type: 3
]]--

if callguard then
  tempTimer(10, [[ cecho("\n<red> - guard arriving in 20 seconds -")]])
  tempTimer(20, [[ cecho("\n<orange> - guard arriving in 10 seconds -")]])
  tempTimer(25, [[ cecho("\n<yellow> - guard arriving in 5 seconds -")]])
  tempTimer(30, [[ cecho("\n<green> - guard should have arrived! -")]])
end
callguard = nil