-- unnamed > For Levi > Levi_062424 > leviticus > LeviAtaxia > Levi  Scripts > Leviticus > MONK > SHIKUDO > FORM SWAP DISPATCH

function formswapdispatch()

form = {}





if ataxia.vitals.form == "Tykonos" and ataxia.vitals.kata >= 5 then
 table.insert(form,"Willow")
end

if ataxia.vitals.form == "Gaital" and ataxia.vitals.kata >= 5 and ataxiaTemp.lastAssess and ataxiaTemp.lastAssess <= 50  then
 table.insert(form,"Maelstrom")
end

if ataxia.vitals.form == "Willow" and ataxia.vitals.kata >= 5 then
 table.insert(form,"Rain")
end

if ataxia.vitals.form == "Rain" and ataxia.vitals.kata >= 5 and llKUR and rlKUR and laRUK and raRUK  then
 table.insert(form,"Oak")
end

if ataxia.vitals.form == "Rain" and ataxia.vitals.kata >= 22 then
 table.insert(form,"Oak")
end



if ataxia.vitals.form == "Oak" and ataxia.vitals.kata >= 11 then
 table.insert(form,"Gaital")
end

if ataxia.vitals.form == "Oak" and ataxia.vitals.kata >= 5 and llKUR and rlKUR and hNEED then
 table.insert(form,"Gaital")
end

if ataxia.vitals.form == "Gaital" and ataxia.vitals.kata >= 11 and not tAffs.prone and not tAffs.damagedhead and ataxiaTemp.lastAssess >= 50 then
 table.insert(form,"Rain")
end

if ataxia.vitals.form == "Maelstrom" and ataxia.vitals.kata >= 11 and not tAffs.prone and not tAffs.damagedhead and ataxiaTemp.lastAssess >= 50 then
 table.insert(form,"Oak")
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
