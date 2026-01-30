if matches[3] then
  zData.db.showData(matches[2], matches[3])
elseif matches[2] then
  zData.db.showData(matches[2])
else
  zData.db.showData()
end