--[[mudlet
type: trigger
name: We're tumbling?
hierarchy:
- Levi_Ataxia
- For Levi
- leviticus
- Ataxia
- Combat/Aff Tracking
- Misc Tracking
- Warnings
- Misc Alerts
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
- pattern: ^You begin to tumble agilely to the (\w+).$
  type: 1
- pattern: ^You begin somersaulting towards the (\w+).$
  type: 1
]]--

ataxia_boxEcho("WE HAVE STARTED TO TUMBLE "..matches[2].."!", "orange")
--clearCmdLine()
--appendCmdLine(matches[2])	

autotumbler = false
if ataxiaTemp.fakeLeave and gmcp.Char.Status.class == "Bard" then
  send("queue add class sing prelude "..gmcp.Char.Status.name.." tumbles out to the "..ataxiaTemp.fakeLeave..".")
  ataxiaTemp.fakeLeave = nil
end

if ataxia.prioritySwaps and ataxia.prioritySwaps.parshield and ataxia.prioritySwaps.parshield.active then
  sendAll("curing priority slickness 25;curing priority paralysis 25",false)
  tempTimer(3.5, [[ ataxia_restorePrio("paralysis");ataxia_restorePrio("slickness") ]])
end