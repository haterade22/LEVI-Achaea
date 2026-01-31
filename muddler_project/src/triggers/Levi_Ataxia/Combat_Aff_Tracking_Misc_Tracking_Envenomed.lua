if ataxia.vitals.knight ~= "Dual Cutting" then
ataxiaTemp.hitCount = 0
if not affs_to_colour then populate_aff_colours() end
local aff = venom_to_aff(matches[2])
envenomList = envenomList or {}

if ataxiaTemp.hitCount == 0 then
  table.insert(envenomList,1,aff)
 
  ataxiaTemp.hitCount = 0
  end  
end
deleteFull()
