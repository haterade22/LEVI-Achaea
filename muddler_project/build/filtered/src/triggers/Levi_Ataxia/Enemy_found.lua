if not table.contains(ataxiaTemp.enemies, matches[2]) and ataxiaNDB_Exists(matches[2]) then
  table.insert(ataxiaTemp.enemies, matches[2])
  
  if table.contains(ataxiaTemp.allies, matches[2]) then
    for n, name in pairs(ataxiaTemp.allies) do
      if name == matches[2] then
        table.remove(ataxiaTemp.allies, n)
        break
      end
    end
  end
end