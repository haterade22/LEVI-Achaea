--[[mudlet
type: trigger
name: Deliverance
hierarchy:
- Levi_Ataxia
- For Levi
- leviticus
- Ataxia
- Combat/Aff Tracking
- Misc Tracking
- Warnings
- Instakills
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
- pattern: ^(\w+) slowly raises \w+ head and you see \w+ eyes glowing bright white.$
  type: 1
- pattern: ^(\w+) bows \w+ head in silent prayer.$
  type: 1
- pattern: ^(.+) is here.  (.*) surrounded by a glowing white nimbus.$
  type: 1
- pattern: ^(.+) is here (.*) surrounded by a glowing white nimbus.$
  type: 1
]]--

if isTargeted(matches[2]) then
	ataxia_boxEcho("TARGET IS USING DELIVERANCE", "NavajoWhite:firebrick")
	send("clearqueue all",false)
	
	if beepBoop and beepBoop.enabled then
		beepBoop.souls = beepBoop.souls or {}
		table.insert(beepBoop.souls, target)
		tempTimer(25, [[ beepBoop_removeSoul("]]..target..[[") ]])
		send("ql",false)
		expandAlias("bbnt")
	end	
end
