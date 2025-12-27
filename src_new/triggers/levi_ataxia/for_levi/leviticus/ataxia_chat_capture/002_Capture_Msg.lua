--[[mudlet
type: trigger
name: Capture Msg
hierarchy:
- Levi_Ataxia
- For Levi
- leviticus
- Ataxia
- Ataxia Chat Capture
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
- pattern: ^(.+), "(.+)"$
  type: 1
]]--

local talker = matches[2]
local speech = matches[3]
local me = gmcp.Char.Status.name
local ignoremsg = false

if table.contains(ataxiaBasher.targetList[gmcp.Room.Info.area], gmcp.Comm.Channel.Text.talker) then
	ignoremsg = true
	if ataxiaBasher.enabled then
		deleteFull()
	end
end

if line:find("guardian spirit of the totem") then
	ignoremsg = true
end

if (ataxiaBasher.shielded and ataxiaBasher.enabled) and gmcp.Comm.Channel.Text.talker == ataxiaTemp.me then deleteLine() end

if muteList[gmcp.Comm.Channel.Text.talker] or ignoremsg then
	deleteFull()
end