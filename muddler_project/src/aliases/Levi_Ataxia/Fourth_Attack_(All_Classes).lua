if gmcp.Char.Status.class == "Apostate" then
apostate_group()
end

if gmcp.Char.Status.class == "Monk" then
lock_base_prios()
end

if gmcp.Char.Status.class == "Serpent" then
serpent_kelp()
end
 
if gmcp.Char.Status.class == "Blademaster" then
bmbs()  
end

if gmcp.Char.Status.class == "Runewarden" and gmcp.Char.Vitals.charstats[3] == "Spec: Dual Blunt" then
dwb_pocketleg()
end

if gmcp.Char.Status.class == "Infernal" and gmcp.Char.Vitals.charstats[4] == "Spec: Dual Blunt" then
  idwb_damageroute3()
end 

if gmcp.Char.Status.class == "Infernal" and gmcp.Char.Vitals.charstats[4] == "Spec: Sword and Shield" then
  infernalpriosdamage()
end

if gmcp.Char.Status.class == "Magi" then
magiPVP()
send("queue addclear freestand mpvp")
end

