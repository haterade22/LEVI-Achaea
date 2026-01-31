function formswapdispatch()

form = {}






if ataxia.vitals.form == "Tykonos" and ataxia.vitals.kata >= 5 then
 table.insert(form,"Willow")
end


if ataxia.vitals.form == "Willow" and ataxia.vitals.kata >= 5 and tAffs.anorexia and tAffs.impatience then
 table.insert(form,"Rain")
end

if ataxia.vitals.form == "Willow" and ataxia.vitals.kata >= 11 then
 table.insert(form,"Rain")
end

if ataxia.vitals.form == "Rain" and ataxia.vitals.kata >= 5 and tAffs.weariness and tAffs.lethargy  then
 table.insert(form,"Oak")
end

if ataxia.vitals.form == "Rain" and ataxia.vitals.kata >= 22 then
 table.insert(form,"Oak")
end



if ataxia.vitals.form == "Oak" and ataxia.vitals.kata >= 11 then
 table.insert(form,"Willow")
end

if ataxia.vitals.form == "Oak" and ataxia.vitals.kata >= 5 and tAffs.asthma and tAffs.slickness and tAffs.paralysis then
 table.insert(form,"Willow")
end

if ataxia.vitals.form == "Gaital" and ataxia.vitals.kata >= 11  then
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
