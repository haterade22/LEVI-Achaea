--[[mudlet
type: trigger
name: Room Info Shortener
hierarchy:
- Levi_Ataxia
- For Levi
- leviticus
- Ataxia
- Basher
- Bashing
attributes:
  isActive: 'no'
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
mStayOpen: 25
mCommand: ''
packageName: ''
mFgColor: '#ff0000'
mBgColor: '#ffff00'
mSoundFile: ''
colorTriggerFgColor: '#000000'
colorTriggerBgColor: '#000000'
patterns:
- pattern: ^(.+). \(.+\)$
  type: 1
- pattern: ^(.+).$
  type: 1
]]--

local x = ataxia.settings.roomshorten

if gmcp.Room.Info.name:lower():find(matches[2]:lower()) then
	if (x == "notmanual" and ataxiaBasher.manual ~= true) or (x == "normal") then
		roomDeleting = true
		deleteLine()
	end
end