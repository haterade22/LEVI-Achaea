if not ataxiaTemp.allies then return end

if table.contains(ataxiaTemp.allies, matches[2]) then
  send("ok",false)
end