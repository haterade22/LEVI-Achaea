if target == matches[2] then
if tAffs.damagedhead then
  if ataxiaTemp.fractures.skullfractures == 0 or ataxiaTemp.fractures.skullfractures == nil then
  ataxiaTemp.fractures.skullfractures = 2
  twohanded_headHit()
  else
  ataxiaTemp.fractures.skullfractures = ataxiaTemp.fractures.skullfractures + 2
  twohanded_headHit()
  end

elseif not tAffs.damagedhead and ataxiaTemp.fractures.skullfractures == 0 or ataxiaTemp.fractures.skullfractures == nil then
  ataxiaTemp.fractures.skullfractures = 1
  twohanded_headHit()
else
  ataxiaTemp.fractures.skullfractures = ataxiaTemp.fractures.skullfractures + 1
  twohanded_headHit()
end
end