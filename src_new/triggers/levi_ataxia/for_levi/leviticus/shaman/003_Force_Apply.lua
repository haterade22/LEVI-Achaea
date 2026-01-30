--[[mudlet
type: trigger
name: Force Apply
hierarchy:
- Levi_Ataxia
- For Levi
- leviticus
- Ataxia
- Combat/Aff Tracking
- Misc Tracking
- Warnings
- Shaman
attributes:
  isActive: 'yes'
  isFolder: 'no'
  isTempTrigger: 'no'
  isMultiline: 'yes'
  isPerlSlashGOption: 'no'
  isColorizerTrigger: 'no'
  isFilterTrigger: 'no'
  isSoundTrigger: 'no'
  isColorTrigger: 'no'
  isColorTriggerFg: 'no'
  isColorTriggerBg: 'no'
triggerType: 0
conditonLineDelta: 1
mStayOpen: 0
mCommand: ''
packageName: ''
mFgColor: '#ff0000'
mBgColor: '#ffff00'
mSoundFile: ''
colorTriggerFgColor: '#000000'
colorTriggerBgColor: '#000000'
patterns:
- pattern: ^(\w+) whispers something to a (Vodun doll|puppet) of (\w+).$
  type: 1
- pattern: ^You take out some salve and quickly rub it on your (.+).$
  type: 1
]]--

if multimatches[1][4] == ataxiaTemp.me and ataxiaNDB_getClass(target) == "Shaman" then
	ataxia_boxEcho("You should probably curseward", "yellow")
	send("queue addclear free curseward",false)
elseif multimatches[1][4] == ataxiaTemp.me and ataxiaNDB_getClass(target) == "Jester" then
	ataxia_boxEcho("You should probably shield soon", "yellow")
	send("queue addclear free touch shield",false)
end