--[[mudlet
type: alias
name: Group (All Classes)
hierarchy:
- Levi_Ataxia
- For Levi
- Levi_062424
- Levi
attributes:
  isActive: 'yes'
  isFolder: 'no'
regex: ^sr$
command: ''
packageName: ''
]]--

if gmcp.Char.Status.class == "Apostate" then
apostate.setMode("group")
apostate.dispatch()
end

--utter lament

if gmcp.Char.Status.class == "Monk" then
shikudolock()
end

if gmcp.Char.Status.class == "Serpent" then
serp_groupattack()
end
 
if gmcp.Char.Status.class == "Blademaster" then
  bm_groupfighting()
end

if gmcp.Char.Status.class == "Runewarden" and gmcp.Char.Vitals.charstats[3] == "Spec: Dual Blunt" then
  dwb_groupsetup()
end

if gmcp.Char.Status.class == "Runewarden" and gmcp.Char.Vitals.charstats[3] == "Spec: Dual Cutting" then
runiedwckelpstack2()
envenom2dwc()
end

if gmcp.Char.Status.class == "Infernal" and gmcp.Char.Vitals.charstats[4] == "Spec: Dual Blunt" then
  idwb_damageroute2()
end 

if gmcp.Char.Status.class == "Infernal" and gmcp.Char.Vitals.charstats[4] == "Spec: Dual Cutting" then
 dwcpriosbasicinfernalgroup()
end 

if gmcp.Char.Status.class == "Infernal" and gmcp.Char.Vitals.charstats[4] == "Spec: Sword and Shield" then
 isnbdamageroute()
end 

if gmcp.Char.Status.class == "Magi" then
  get_resonance()
  MagiWaterFocus()
end

