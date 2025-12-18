-- unnamed > For Levi > Levi_062424 > mudlet-mapper_24 > Mudlet Mapper > Game-specific > StickMUD > mmp.stickmudStopSpeedwalkForWrongDir

function mmp.stickmudStopSpeedwalkForWrongDir()
  if mmp.game and mmp.game ~= "stickmud" then
    return
  end
  if #mmp.speedWalkPath > 0 then
    echo("The way \"" .. gmcp.Room.WrongDir .. "\" is blocked. Stopping speedwalk.")
    mmp.stop()
  end
end