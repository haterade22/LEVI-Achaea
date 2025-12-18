-- unnamed > For Levi > Levi_062424 > mudlet-mapper_24 > Mudlet Mapper > Game-specific > Ashyria > mmp.asteriaStopSpeedwalkForWrongDir

function mmp.ashyriaStopSpeedwalkForWrongDir()
  if mmp.game and mmp.game ~= "ashyria" then
    return
  end
  if #mmp.speedWalkPath > 0 then
    echo("Can't go \"" .. gmcp.Room.WrongDir .. "\". Stopping speedwalk.")
    mmp.stop()
  end
end