--[[mudlet
type: trigger
name: Locate Logic
hierarchy:
- Levi_Ataxia
- For Levi
- leviticus
- LeviAtax
- Leviticus
- MINE ALL MINE
- Locate
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
- pattern: ^You see that (\w+) is at (.+)\.$
  type: 1
]]--

mmp.locateAndEcho(matches[3], matches[2])
if locateon == true then
  local t = mmp.searchRoomExact(matches[3])
  local roomId = ""
  if next(t) then
    local k, v = next(t)
    roomId = " (" .. (type(k) == "number" and k or v) .. ")"
  end
  send("tell " .. locateperson .. " " .. matches[2] .. " is at " .. matches[3] .. roomId)
end
locateon = false