--[[mudlet
type: alias
name: Second Attack (All Classes)
hierarchy:
- Levi_Ataxia
attributes:
  isActive: 'yes'
  isFolder: 'no'
regex: ^xx$
command: ''
packageName: ''
]]--

--vaalbardlock()
--bardvenomprios()
if gmcp.Char.Status.class == "Bard" then
levibardtwo()
end
if gmcp.Char.Status.class == "Monk" then
  if ataxia.vitals.stance then
    tekura.dispatch.run()
  else
    shikudo.dispatch()
  end
end

if gmcp.Char.Status.class == "Blademaster" then
bmdq()
end

if gmcp.Char.Status.class == "Runewarden" and gmcp.Char.Vitals.charstats[3] == "Spec: Dual Cutting" then
levidwcheadprep()
end


if gmcp.Char.Status.class == "Runewarden" and gmcp.Char.Vitals.charstats[3] == "Spec: Dual Blunt" then
dwbRunie.setMode("pulp")
dwbRunie.dispatch()
end

if gmcp.Char.Status.class == "Blue Dragon" or gmcp.Char.Status.class == "Red Dragon" or gmcp.Char.Status.class == "Green Dragon" or gmcp.Char.Status.class == "Black Dragon" or gmcp.Char.Status.class == "Golden Dragon" or gmcp.Char.Status.class == "Silver Dragon" then
send("wield shield;dragoncurse " ..target.. " sensitivity 1;dragonroar " ..target)
end


if gmcp.Char.Status.class == "Depthswalker" then
depthswalker.dispatch()
end

if gmcp.Char.Status.class == "Magi" then
MagiSalveFocus()
end

--Infernal
if gmcp.Char.Status.class == "Infernal" and gmcp.Char.Vitals.charstats[4] == "Spec: Dual Blunt" then
idwb_skullfractures()
end
if gmcp.Char.Status.class == "Infernal" and gmcp.Char.Vitals.charstats[4] == "Spec: Dual Cutting" then
infernalDWC2LVivisect()
end
if gmcp.Char.Status.class == "Infernal" and gmcp.Char.Vitals.charstats[4] == "Spec: Two Handed" then
infernaltwohand()
enableTimer("Battlefury Perceive")
--enableTimer("TargetOutOfRoom")
end
if gmcp.Char.Status.class == "Infernal" and gmcp.Char.Vitals.charstats[4] == "Spec: Sword and Shield" then
infernalpriosblackout()
end

if gmcp.Char.Status.class == "Apostate" then
apostate.setMode("mental")
apostate.dispatch()
end
if gmcp.Char.Status.class == "Serpent" then
  serp_setmode_hypnolock()
end
if gmcp.Char.Status.class == "Psion" then
levipsionflurry()
end

if gmcp.Char.Status.class == "Pariah" then
levipariahscourgetest()
end
