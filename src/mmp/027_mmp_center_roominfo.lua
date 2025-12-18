-- unnamed > For Levi > mudlet-mapper > Mudlet Mapper > Center view via GMCP > mmp_center_roominfo

function mmp_center_roominfo()
  -- lusternia has gmcp.Room.Players before gmcp.Room.Info is created
  if gmcp.Room.Info then centerview(gmcp.Room.Info.num) end
end