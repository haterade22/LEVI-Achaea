--[[mudlet
type: trigger
name: Tarot Lust
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
- pattern: ^(\w+) quickly flings a tarot card at you, and you feel unreasonable lust for \w+.$
  type: 1
]]--

if not ataxia.settings.lustlist then
	ataxia.settings.lustlist = {}
end

if not ataxia.lustedto then
	ataxia.lustedto = {}
end

local person = matches[2]
if not table.contains(ataxia.lustedto, person) then
  table.insert(ataxia.lustedto, person)
end

ataxia_boxEcho("Got lusted by "..person, "red")

if ataxia_needReject() then
	send("queue addclear free reject "..person..ataxia.settings.separator.."enemy "..person,false)
end
