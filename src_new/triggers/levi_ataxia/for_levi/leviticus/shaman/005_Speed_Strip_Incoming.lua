--[[mudlet
type: trigger
name: Speed Strip Incoming
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
- pattern: Your speed defence is destroyed by an unseen force.
  type: 3
]]--

if ataxiaNDB_Exists(target) then
	if ataxiaNDB_getClass(target) == "Jester" then
		ataxia_boxEcho("slowlock incoming - shield now", "yellow")
		send("queue addclear free touch shield",false)
	else
		ataxia_boxEcho("slowlock incoming - curseward now", "yellow")
		send("queue addclear free curseward",false)	
	end
end