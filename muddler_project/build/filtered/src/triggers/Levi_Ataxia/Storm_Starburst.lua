if magi and magi.storm and magi.storm.targets then
  local name = matches[2]
  if table.contains(magi.storm.targets, name) then
    magi.storm.starbursted[name] = true
  end
end
