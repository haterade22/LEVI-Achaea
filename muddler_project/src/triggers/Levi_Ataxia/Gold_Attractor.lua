if zData.char.ogold ~= tonumber(gmcp.Char.Status.gold) then
  zData.char.gold = zData.char.gold + (tonumber(gmcp.Char.Status.gold) - zData.char.ogold)
  zData.char.ogold = tonumber(gmcp.Char.Status.gold)
end