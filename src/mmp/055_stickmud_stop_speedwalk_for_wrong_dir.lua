-- unnamed > For Levi > mudlet-mapper > Mudlet Mapper > Game-specific > StickMUD > stickmud_stop_speedwalk_for_wrong_dir

function stickmud_stop_speedwalk_for_wrong_dir()
  if mmp.game and mmp.game ~= "StickMUD" then
    return
  end
  if #mmp.speedWalkPath > 0 then
    echo("The way \"" .. gmcp.Room.WrongDir .. "\" is blocked. Stopping speedwalk.")
    mmp.stop()
  end
end