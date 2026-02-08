if not table.contains(ataxiaTemp.allies, matches[2]) then
  table.insert(ataxiaTemp.allies, matches[2])

  if table.contains(ataxiaTemp.enemies, matches[2]) then
    for n, name in pairs(ataxiaTemp.enemies) do
      if name == matches[2] then
        table.remove(ataxiaTemp.enemies, n)
        break
      end
    end
  end  
end