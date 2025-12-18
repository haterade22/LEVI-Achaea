-- unnamed > For Levi > Levi_062424 > mudlet-mapper_24 > Mudlet Mapper > Center view via GMCP > mmp.centerRoominfo

function mmp.centerRoominfo()
  -- lusternia has gmcp.Room.Players before gmcp.Room.Info is created
  if gmcp.Room.Info then centerview(gmcp.Room.Info.num) end
end