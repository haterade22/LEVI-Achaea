--[[mudlet
type: trigger
name: Prospect General
hierarchy:
- Levi_Ataxia
- For Levi
- leviticus
- LeviAtax
- Leviticus
- Mining
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
- pattern: ^You pay the 5000 gold sovereigns in order to hire a general purpose prospecting crew. They swiftly set off to
    search for untapped riches\.$
  type: 1
]]--

send("clan mmc tell Started prospect for - General "..gmcp.Room.Info.name.." in "..gmcp.Room.Info.area)

tempTimer(3600, [[ataxiaEcho("PROSPECT AVAILABLE");ataxiaEcho("PROSPECT AVAILABLE");ataxiaEcho("PROSPECT AVAILABLE";ataxiaEcho("PROSPECT AVAILABLE";ataxiaEcho("PROSPECT AVAILABLE";ataxiaEcho("PROSPECT AVAILABLE";ataxiaEcho("PROSPECT AVAILABLE";ataxiaEcho("PROSPECT AVAILABLE";ataxiaEcho("PROSPECT AVAILABLE"]])