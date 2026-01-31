if gmcp.Char.Status.class == "Monk" then
lock_base_prios()
formswaplock()
end

if gmcp.Char.Status.class == "Bard" then
bardvenomprioslimb()
end
if gmcp.Char.Status.class == "Runewarden" and gmcp.Char.Vitals.charstats[3] == "Spec: Dual Cutting" then
dwcprioslimb()
end
if gmcp.Char.Status.class == "Infernal" and gmcp.Char.Vitals.charstats[4] == "Spec: Sword and Shield" then
infernalpriosblackout()
end

if gmcp.Char.Status.class == "Runewarden" and gmcp.Char.Vitals.charstats[3] == "Spec: Dual Blunt" then
dwb_skullfracturesantishield()
end


if gmcp.Char.Status.class == "Infernal" and gmcp.Char.Vitals.charstats[4] == "Spec: Two Handed" then
infernaltwohandprios()
enableTimer("Battlefury Perceive")
--enableTimer("TargetOutOfRoom")
end
if gmcp.Char.Status.class == "Depthswalker" then
depthswalker_lockroute()
end

if gmcp.Char.Status.class == "Magi" then
get_resonance()
MagiWaterFocus()
end


if gmcp.Char.Status.class == "Infernal" and gmcp.Char.Vitals.charstats[4] == "Spec: Dual Blunt" then
idwb_viviroute()
end
if gmcp.Char.Status.class == "Infernal" and gmcp.Char.Vitals.charstats[4] == "Spec: Dual Cutting" then
infernaldwcvivi3limblevitest()
end

