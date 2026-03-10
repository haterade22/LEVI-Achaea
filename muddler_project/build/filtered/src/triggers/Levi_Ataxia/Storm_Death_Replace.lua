if magi and magi.storm and magi.storm.targets then
  local deadName = matches[2]
  if table.contains(magi.storm.targets, deadName) then
    magi.storm.replaceDead(deadName)
  end
end
