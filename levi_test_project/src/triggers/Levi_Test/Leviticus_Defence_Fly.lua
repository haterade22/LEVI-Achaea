if target == matches[2] then
  send("pt " ..target.. ": Flying!")
  if gmcp.Char.Status.class == "Runewarden" and rtiwaz == true then
    send("queue addclear free empower tiwaz " ..target)
  elseif ataxiaNDB.players[matches[2]].city ~= "Mhaldor" then
    send("queue addclear free touch tentacle " ..target)
  end
end