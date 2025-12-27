--[[mudlet
type: alias
name: Add Note
hierarchy:
- Levi_Ataxia
- For Levi
- Levi_062424
- Levi
- Ataxia-DownloadThis
- Ataxia
- Ataxia NDB
- Actions
- Notes
attributes:
  isActive: 'yes'
  isFolder: 'no'
regex: ^an noteadd (\w+) (.+)$
command: ''
packageName: ''
]]--

ataxiaNDB.player_Notes = ataxiaNDB.player_Notes or {}
local player, note = matches[2]:title(), matches[3]
if not ataxiaNDB_Exists(player) then
  ataxia_Echo("That player isn't currently in the database.")
  return
end

ataxiaNDB.player_Notes[player] = ataxiaNDB.player_Notes[player] or {}
table.insert(ataxiaNDB.player_Notes[player], #ataxiaNDB.player_Notes[player]+1, note)
ataxia_Echo("Added note to "..player..":")
cecho("\n "..note)