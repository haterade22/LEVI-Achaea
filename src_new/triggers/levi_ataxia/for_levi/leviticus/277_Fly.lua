--[[mudlet
type: trigger
name: Fly
hierarchy:
- Levi_Ataxia
- For Levi
- leviticus
- LeviAtax
- Leviticus
- Defence
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
- pattern: ^(\w+) is quickly carried up into the skies\.$
  type: 1
]]--

if target == matches[2] then
  send("pt " ..target.. ": Flying!")
  if gmcp.Char.Status.class == "Runewarden" and rtiwaz == true then
    send("queue addclear free empower tiwaz " ..target)
  elseif ataxiaNDB.players[matches[2]].city ~= "Mhaldor" then
    send("queue addclear free touch tentacle " ..target)
  end
end