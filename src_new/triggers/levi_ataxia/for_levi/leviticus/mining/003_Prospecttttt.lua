--[[mudlet
type: trigger
name: Prospecttttt
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
- pattern: ^You pay the 5000 gold sovereigns in order to hire a general purpose prospecting crew.
  type: 1
- pattern: ^You pay the 1500 gold sovereigns to hire a specialised prospecting crew. They swiftly set off to hunt for untapped
    reserves of (\w+)\.$
  type: 1
]]--

send("clan mmc tell Started full prospect at " .. gmcp.Room.Info.area)

tempTimer(3600, [[ataxiaEcho("PROSPECT AVAILABLE");ataxiaEcho("PROSPECT AVAILABLE");ataxiaEcho("PROSPECT AVAILABLE";ataxiaEcho("PROSPECT AVAILABLE";ataxiaEcho("PROSPECT AVAILABLE";ataxiaEcho("PROSPECT AVAILABLE";ataxiaEcho("PROSPECT AVAILABLE";ataxiaEcho("PROSPECT AVAILABLE";ataxiaEcho("PROSPECT AVAILABLE"]])