ataxiaNDB.player_Notes = ataxiaNDB.player_Notes or {}
local player = matches[2]:title()
if not ataxiaNDB_Exists(player) then
  ataxia_Echo("That player isn't currently in the database.")
  return
end

if not ataxiaNDB.player_Notes[player] or #ataxiaNDB.player_Notes[player] == 0 then
  ataxia_Echo("That player currently has no notes.")
  return
end

ataxia_Echo("Showing notes for "..player..":")
for num, note in pairs(ataxiaNDB.player_Notes[player]) do
  cecho("\n  <DarkSlateBlue>"..num..") <reset>"..note)
end
cecho("\n ")