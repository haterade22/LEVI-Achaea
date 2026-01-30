ataxiaNDB.player_Notes = ataxiaNDB.player_Notes or {}
local player, note = matches[2]:title(), tonumber(matches[3])
if not ataxiaNDB_Exists(player) then
  ataxia_Echo("That player isn't currently in the database.")
  return
end

if not ataxiaNDB.player_Notes[player] or #ataxiaNDB.player_Notes[player] == 0 then
  ataxia_Echo("That player currently has no notes.")
  return
end

if ataxiaNDB.player_Notes[player][note] then
  table.remove(ataxiaNDB.player_Notes[player], note)
  ataxia_Echo("Removed note from "..player.." with id of "..note..".")
else
  ataxia_Echo("There is no note for "..player.." with id of "..note..".")
end