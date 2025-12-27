--[[mudlet
type: alias
name: Fourth Attack (All Classes)
hierarchy:
- Levi_Ataxia
- For Levi
- Levi_062424
- Levi
attributes:
  isActive: 'yes'
  isFolder: 'no'
regex: ^vv$
command: ''
packageName: ''
]]--

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
tjew = false
bmgrouplock()

  if tAffs.rebounding or tAffs.shield then
    send("queue addclear free assess "..target.. ";raze " ..target.. " " ..tstrike)
  else
    send("queue addclear free infuse ice;assess " ..target.. " ;pommelstrike " ..target.. " " ..tstrike)
  end
  
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

