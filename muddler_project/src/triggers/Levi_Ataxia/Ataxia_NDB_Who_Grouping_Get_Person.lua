if not matches[3] then
  whogroups.unknown = whogroups.unknown or {}
  table.insert(whogroups.unknown, matches[2])
  table.sort(whogroups.unknown)
else
  whogroups[matches[3]] = whogroups[matches[3]] or {}
  table.insert(whogroups[matches[3]], matches[2])
  table.sort(whogroups[matches[3]])  
end

deleteLine()