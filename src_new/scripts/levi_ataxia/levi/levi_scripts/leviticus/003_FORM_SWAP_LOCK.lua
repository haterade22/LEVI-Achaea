--[[mudlet
type: script
name: FORM SWAP LOCK
hierarchy:
- Levi_Ataxia
- LEVI
- Levi  Scripts
- Leviticus
- MONK
- SHIKUDO
attributes:
  isActive: 'yes'
  isFolder: 'no'
packageName: ''
]]--

function formswaplock()

form = {}






if ataxia.vitals.form == "Tykonos" and ataxia.vitals.kata >= 5 then
 table.insert(form,"Willow")
end

if ataxia.vitals.form == "Gaital" and ataxia.vitals.kata >= 5 and ataxiaTemp.lastAssess and ataxiaTemp.lastAssess <= 50  then
 table.insert(form,"Maelstrom")
end

if ataxia.vitals.form == "Gaital" and ataxia.vitals.kata >= 5 and tAffs.brokenrightleg and tAffs.brokenleftleg  then
 table.insert(form,"Maelstrom")
end

if ataxia.vitals.form == "Gaital" and ataxia.vitals.kata >= 11 then
 table.insert(form,"Maelstrom")
end

if ataxia.vitals.form == "Maelstrom" and ataxia.vitals.kata >= 11 then
 table.insert(form,"Oak")
end

if ataxia.vitals.form == "Maelstrom" and ataxia.vitals.kata >= 5 and tAffs.damagedleftarm and tAffs.damagedrightarm and tAffs.addiction then
 table.insert(form,"Oak")
end

if ataxia.vitals.form == "Willow" and ataxia.vitals.kata >= 5 then
 table.insert(form,"Rain")
end

if ataxia.vitals.form == "Rain" and ataxia.vitals.kata >= 5 and leftlegpreppedKUR and rightlegpreppedKUR and leftarmpreppedRUK and rightarmpreppedRUK then
 table.insert(form,"Oak")
end

if ataxia.vitals.form == "Rain" and ataxia.vitals.kata >= 23 then
 table.insert(form,"Oak")
end



if ataxia.vitals.form == "Oak" and ataxia.vitals.kata >= 11 then
 table.insert(form,"Gaital")
end

if ataxia.vitals.form == "Oak" and ataxia.vitals.kata >= 5 and leftlegpreppedKUR and rightlegpreppedKUR and leftarmpreppedRUK and rightarmpreppedRUK then
 
 table.insert(form,"Gaital")
end

if ataxia.vitals.form == "Oak" and ataxia.vitals.kata >= 5 and tAffs.slickness and tAffs.asthma and tAffs.brokenrightarm and tAffs.brokenleftarm then
 table.insert(form,"Willow")
end




if ataxia.vitals.form == "Gaital" and ataxia.vitals.kata >= 11 then
 table.insert(form,"Rain")
end

-- BASE --


if ataxia.vitals.form == "Tykonos" and form[1] ~= "Willow" then
 table.insert(form,"Tykonos")
end

if ataxia.vitals.form == "Willow" and form[1] ~= "Rain" then
 table.insert(form,"Willow")
end


if ataxia.vitals.form == "Rain" and form[1] ~= "Oak" and form[1] ~= "Tykonos" then
 table.insert(form,"Rain")
end

if ataxia.vitals.form == "Oak" and (form[1] ~= "Willow" or form[1] ~= "Gaital") then
 table.insert(form,"Oak")
end


if ataxia.vitals.form == "Gaital" and form[1] ~= "Rain" and form[1] ~= "Maelstrom" then
 table.insert(form,"Gaital")
end

if ataxia.vitals.form == "Maelstrom" and form[1] ~= "Oak" then
 table.insert(form,"Maelstrom")
end


end
