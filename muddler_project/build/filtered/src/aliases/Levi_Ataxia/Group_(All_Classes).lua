if gmcp.Char.Status.class == "Apostate" then
  apostate_group()
end

--utter lament

if gmcp.Char.Status.class == "Monk" then
 shikudoLock.dispatch()
end

if gmcp.Char.Status.class == "Serpent" then
serp_ekanelia_offense()
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

