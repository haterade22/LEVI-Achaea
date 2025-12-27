--[[mudlet
type: trigger
name: Accelerate
hierarchy:
- Levi_Ataxia
- For Levi
- leviticus
- Ataxia
- Combat/Aff Tracking
- Add Afflictions
- Classes K-S
- Pariah
- Misc
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
- pattern: ^You raise your right hand, directing the arcane flows to speed the beating of (\w+)'s heart.$
  type: 1
]]--

if affTimers.voyria then
  affTimers.voyria = affTimers.voyria - 10
  local timeRemaining = 30 - affDuration("voyria")
  deleteLine()
  cecho("\n   <green>"..utf8.char(187).." <Orange>Accelerated VOYRIA <green>"..utf8.char(171))
  if timeRemaining < 0 then
    cecho(" <red>Used too many times, duration reset!")
  else
    cecho(" <green>Time left: "..timeRemaining)
  end
end

if taccelerates == 0 then
taccelerates = 1
elseif taccelerates == 1 then
taccelerates = 2
end