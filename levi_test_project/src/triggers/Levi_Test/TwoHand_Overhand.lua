local warhammers = {"warhammer", "hammer", "Warhammer","Hammer"}
local blades = {"sword", "Sword", "blade", "Blade"}

for i in pairs(warhammers) do
 if string.find(multimatches[1][3], warhammers[i]) then
  slc.overhand_weapon = "hammer"
 end
end

for i in pairs(blades) do
 if string.find(multimatches[1][3], blades[i]) then
  slc.overhand_weapon = "blade"
 end
end

slc_last_limb = "head"
