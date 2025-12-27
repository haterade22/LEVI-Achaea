--[[mudlet
type: trigger
name: Force Follow
hierarchy:
- Levi_Ataxia
- For Levi
- leviticus
- Ataxia
- Combat/Aff Tracking
- Misc Tracking
- Warnings
- Lust
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
- pattern: ^The implacable whisper of (\w+) enters your ear, and you must obey.$
  type: 1
]]--

if not ataxia.settings.lustlist then
	ataxia.settings.lustlist = {}
end

local person = matches[2]

if not table.contains(ataxia.settings.lustlist, person) then
	ataxia_boxEcho("FORCED TO FOLLOW "..person, "red")
	send("queue addclear free lose "..person,false)
end
