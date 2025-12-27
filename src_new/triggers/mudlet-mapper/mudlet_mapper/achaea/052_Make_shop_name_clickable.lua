--[[mudlet
type: trigger
name: Make shop name clickable
hierarchy:
- mudlet-mapper
- Mudlet Mapper
- Achaea
- Directory - Catch shop entry
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
- pattern: ^.{47} (.+)$
  type: 1
]]--

selectCaptureGroup(2)
replace("")
rooms = mmp.searchRoomExact(matches[2])
local roomnum=next(rooms,nil)
if roomnum == nil or next(rooms, roomnum) then
  cecho("<white>(<sky_blue>" .. matches[2] .. "<white>)")
else
  local r, g, b = unpack(color_table["cyan"])
  cecho("<white>(")
  setTextFormat("", 0, 0, 0, r, g, b, false, true, false)
  echoLink(matches[2], [[mmp.gotoRoom(]] .. roomnum .. [[)]], "Walk to " .. matches[2] .. ".", true)
  cecho("<white>)")
  resetFormat()
end