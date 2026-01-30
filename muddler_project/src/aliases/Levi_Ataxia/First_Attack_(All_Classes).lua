if gmcp.Char.Status.class == "Blue Dragon" or gmcp.Char.Status.class == "Red Dragon" or gmcp.Char.Status.class == "Green Dragon" or gmcp.Char.Status.class == "Black Dragon" or gmcp.Char.Status.class == "Golden Dragon" or gmcp.Char.Status.class == "Silver Dragon" then
levidragongroup()
end
if gmcp.Char.Status.class == "Monk" then
shikudo.dispatch()
end

if gmcp.Char.Status.class == "Bard" then
levibardone()
end



if gmcp.Char.Status.class == "Psion" then
levipsionmind()
end
  
if gmcp.Char.Status.class == "Runewarden" and gmcp.Char.Vitals.charstats[3] == "Spec: Dual Cutting" then
dwcprioslimb()
end

if gmcp.Char.Status.class == "Infernal" and gmcp.Char.Vitals.charstats[4] == "Spec: Sword and Shield" then
infernalpriosblackout()
end

if gmcp.Char.Status.class == "Infernal" and gmcp.Char.Vitals.charstats[4] == "Spec: Dual Blunt" then
idwb_torsodamage()
end

if gmcp.Char.Status.class == "Runewarden" and gmcp.Char.Vitals.charstats[3] == "Spec: Dual Blunt" then
dwb_torsodamage()
end

if gmcp.Char.Status.class == "Infernal" and gmcp.Char.Vitals.charstats[4] == "Spec: Two Handed" then
infernaltwohandprios()
enableTimer("Battlefury Perceive")
--enableTimer("TargetOutOfRoom")
end

if gmcp.Char.Status.class == "Infernal" and gmcp.Char.Vitals.charstats[4] == "Spec: Dual Cutting" then
 infernalDWCVivisect()
end


if gmcp.Char.Status.class == "Depthswalker" then
depthswalker_damageroute()
end

if gmcp.Char.Status.class == "Infernal" and gmcp.Char.Vitals.charstats[4] == "Spec: Sword and Shield" then
  if ataxiaNDB_getClass(target) ~= "Priest" or ataxiaNDB_getClass(target) ~= "Occultist" or ataxiaNDB_getClass(target) ~= "Pariah" then
    isnbdamageroute()
  else
    isnbdamageroute()
  end
end

if gmcp.Char.Status.class == "Blademaster" then
 bmd()
end

if gmcp.Char.Status.class == "Magi" then

MagiWaterFocus()
end


if gmcp.Char.Status.class == "Apostate" then
apostate.setMode("lock")
apostate.dispatch()
end


if gmcp.Char.Status.class == "Serpent" then
serp_setmode_auto()
end

if gmcp.Char.Status.class == "Pariah" then
levipariahlatencytest()
end

