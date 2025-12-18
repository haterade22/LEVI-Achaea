-- unnamed > For Levi > Levi_062424 > mudlet-mapper_24 > Mudlet Mapper > Game-specific > Dragonswords > mmp.dragonswordsStopSpeedwalkForWrongDir

function mmp.dragonswordsStopSpeedwalkForWrongDir()
  if mmp.game and mmp.game ~= "dragonswords" then
    return
  end
  if #mmp.speedWalkPath > 0 then
    echo("The way \"" .. gmcp.Room.WrongDir .. "\" is blocked. Stopping speedwalk.")
    mmp.stop()
  end
end