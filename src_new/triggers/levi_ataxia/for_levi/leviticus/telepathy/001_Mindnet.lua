--[[mudlet
type: trigger
name: Mindnet
hierarchy:
- Levi_Ataxia
- For Levi
- leviticus
- Ataxia
- Class Stuff
- Monk
- Telepathy
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
- pattern: ^(\w+) has (entered|left) the area.$
  type: 1
]]--

if not ataxiaNDB_Exists(matches[2]) then
  ataxiaNDB_Acquire(matches[2]:title())
end

if ataxia_paused() then return end

if ataxiaNDB.players[matches[2]].city ~= "Mhaldor" then
    send("pt "..matches[2].." "..(matches[3] == "entered" and "IN!" or " IS OUT!"))
    ataxiaBasher_alert("Normal")
end


--if table.contains(ataxiaNDB.cityEnemies, matches[2]) then
  -- send("pt "..matches[2].." "..(matches[3] == "entered" and "IN!" or "OUT!"))
 if ataxiaNDB_getCitizenship(ataxiaTemp.me) == gmcp.Room.Info.area and ataxiaNDB.players[matches[2]].city ~= "Mhaldor" then
    send("clt6 "..matches[2].." "..(matches[3] == "entered" and "has entered" or "has left").." "..gmcp.Room.Info.area)
    ataxiaBasher_alert("Normal")
  end


if ataxiaTemp.enemies and table.contains(ataxiaTemp.enemies, matches[2]) then
  ataxiaBasher_alert("Normal")
  if ataxiaBasher.enabled then
    ataxia_boxEcho("Enemy has entered the area", "green")
  end
  end
