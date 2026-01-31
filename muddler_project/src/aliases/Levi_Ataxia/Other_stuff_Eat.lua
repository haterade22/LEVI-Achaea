if ataxiaTemp.riftContents and ataxiaTemp.riftContents[matches[2]:lower()] then
  send("outrift "..matches[2]..ataxia.settings.separator.."eat "..matches[2],false)
else
  send("eat "..matches[2],false)
end