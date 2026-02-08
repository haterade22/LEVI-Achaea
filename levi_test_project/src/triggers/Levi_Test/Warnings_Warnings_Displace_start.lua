ataxia_setWarning("getting displaced", 2.5)
local currentroom = gmcp.Room.Info.name

ataxiaTemp.displacerooms = ataxiaTemp.displacerooms or {}
ataxiaTemp.displacerooms[#ataxiaTemp.displacerooms+1] = currentroom

tempTimer(9+1, function()
  local i = table.index_of(ataxiaTemp.displacerooms, currentroom)
  if i then
    table.remove(ataxiaTemp.displacerooms, i)
    ataxia_Echo(currentroom.." should be safe to move back into now.")
  end
end)