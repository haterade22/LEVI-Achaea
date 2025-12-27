--[[mudlet
type: trigger
name: Allies
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
- pattern: ^You feel an unusually strong lust for (\w+).
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

selectString(matches[2], 1)
fg("red")
deselect()

if ataxia_needReject() then
	send("queue addclear free reject "..ataxiaTemp.reject..ataxia.settings.separator.."enemy "..person,false)
end
