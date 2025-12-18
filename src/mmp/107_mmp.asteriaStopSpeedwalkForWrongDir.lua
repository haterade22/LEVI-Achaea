-- unnamed > For Levi > Levi_062424 > mudlet-mapper_24 > Mudlet Mapper > Game-specific > Asteria > mmp.asteriaStopSpeedwalkForWrongDir

function mmp.asteriaStopSpeedwalkForWrongDir()
  if mmp.game and mmp.game ~= "asteria" then
    return
  end
  if #mmp.speedWalkPath > 0 then
    echo("Can't go \"" .. gmcp.Room.WrongDir .. "\". Stopping speedwalk.")
    mmp.stop()
  end
end