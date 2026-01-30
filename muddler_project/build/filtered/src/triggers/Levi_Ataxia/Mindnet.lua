if not ataxiaNDB_Exists(matches[2]) then
  ataxiaNDB_Acquire(matches[2]:title())
end

if ataxia_paused() then return end

-- Check if raid mode is enabled (report everyone)
if ataxia.settings.raid and ataxia.settings.raid.enabled then
  send("pt "..matches[2].." "..(matches[3] == "entered" and "IN!" or "OUT!"))
  ataxiaBasher_alert("Normal")
-- Only process if we're in Mhaldor or Annwyn
elseif gmcp.Room.Info.area == "Mhaldor" then
  -- Only alert for city enemies in Mhaldor
  if table.contains(ataxiaNDB.cityEnemies, matches[2]) then
    send("pt "..matches[2].." "..(matches[3] == "entered" and "IN!" or "OUT!"))
    send("clt6 "..matches[2].." "..(matches[3] == "entered" and "has entered" or "has left").." "..gmcp.Room.Info.area)
    ataxiaBasher_alert("Normal")
  end
elseif gmcp.Room.Info.area == "Annwyn" then
  -- Alert for everyone in Annwyn (free PK area)
  send("pt "..matches[2].." "..(matches[3] == "entered" and "IN!" or "OUT!"))
  ataxiaBasher_alert("Normal")
end


if ataxiaTemp.enemies and table.contains(ataxiaTemp.enemies, matches[2]) then
  ataxiaBasher_alert("Normal")
  if ataxiaBasher.enabled then
    ataxia_boxEcho("Enemy has entered the area", "green")
  end
  end
