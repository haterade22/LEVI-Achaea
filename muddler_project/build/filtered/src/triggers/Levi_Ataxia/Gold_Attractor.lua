if ataxia.data.char.ogold ~= tonumber(gmcp.Char.Status.gold) then
  ataxia.data.char.gold = ataxia.data.char.gold + (tonumber(gmcp.Char.Status.gold) - ataxia.data.char.ogold)
  ataxia.data.char.ogold = tonumber(gmcp.Char.Status.gold)
end