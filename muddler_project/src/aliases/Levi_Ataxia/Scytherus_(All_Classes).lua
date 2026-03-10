if gmcp.Char.Status.class == "Serpent" then
  serp_setmode_scytherus()
  serp_ekanelia_offense()
end

if gmcp.Char.Status.class == "Magi" then
  if magi.storm and magi.storm.fire then
    magi.storm.selectTargets()
    magi.storm.fire()
  else
    send("queue addclearfull freestand cast stormhammer at " .. (target or ""))
  end
end
