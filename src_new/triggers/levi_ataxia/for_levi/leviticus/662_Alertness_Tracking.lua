--[[mudlet
type: trigger
name: Alertness Tracking
hierarchy:
- Levi_Ataxia
- For Levi
- leviticus
- Ataxia
- Combat/Aff Tracking
- Misc Tracking
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
- pattern: ^Your enhanced senses inform you that (\w+) has entered (.+?)(?:, to the| at your) (\w+)\.$
  type: 1
]]--

ataxiaTemp.alertness = ataxiaTemp.alertness or {}
local person, dir = matches[2], matches[4]

if dir == "location" then dir = "here" end

--if matches[4] == "location" and (ataxiaNDB.players[matches[2]].city ~= "None" or ataxiaNDB.players[matches[2]].city ~= "Unknown" or ataxiaNDB.players[matches[2]].city ~= "Undercity") then
--send("queue addclear free soulbleed shackle living")
--end

ataxiaTemp.alertness[dir] = ataxiaTemp.alertness[dir] or {}
if not table.contains(ataxiaTemp.alertness[dir], person) then
  table.insert(ataxiaTemp.alertness[dir], person)
end
table.sort(ataxiaTemp.alertness[dir])

deleteLine()

if beckonmode then 
send("cq all;demon beckon "..person)
end