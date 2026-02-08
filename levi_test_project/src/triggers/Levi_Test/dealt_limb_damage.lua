lb.addHit(matches.name, matches.limb, tonumber(matches.amount))
if partyrelay and not ataxia.afflictions.aeon then
send("pt Hit " ..matches.name.." "..matches.limb.. " for "..matches.amount.."%")
end

if gmcp.Char.Status.class == "Runewarden" and gmcp.Char.Vitals.charstats[3] == "Spec: Dual Cutting" then
ataxiaTables.limbData.dwcSlash = tonumber(matches.amount)
end

if gmcp.Char.Status.class == "Runewarden" and gmcp.Char.Vitals.charstats[3] == "Spec: Sword and Shield" then
ataxiaTables.limbData.snbSlice = tonumber(matches.amount)
end

if gmcp.Char.Status.class == "Infernal" and gmcp.Char.Vitals.charstats[4] == "Spec: Dual Cutting" then
ataxiaTables.limbData.dwcSlash = tonumber(matches.amount)
end


if gmcp.Char.Status.class == "Infernal" and gmcp.Char.Vitals.charstats[4] == "Spec: Sword and Shield" then
ataxiaTables.limbData.snbSlice = tonumber(matches.amount)
end



if gmcp.Char.Status.class == "Blue Dragon" or gmcp.Char.Status.class == "Red Dragon" or gmcp.Char.Status.class == "Green Dragon" or gmcp.Char.Status.class == "Black Dragon" or gmcp.Char.Status.class == "Golden Dragon" or gmcp.Char.Status.class == "Silver Dragon" then
ataxiaTables.limbData.dragonRend = tonumber(matches.amount)
end

if gmcp.Char.Status.class == "Priest" then
ataxiaTables.limbData.priestSmite = tonumber(matches.amount)
end
if gmcp.Char.Status.class == "Bard" then
ataxiaTables.limbData.bardRapier = tonumber(matches.amount)
end

if gmcp.Char.Status.class == "Psion" then
ataxiaTables.limbData.psionweaves = tonumber(matches.amount)
end
