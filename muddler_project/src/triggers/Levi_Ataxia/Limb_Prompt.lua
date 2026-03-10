cecho(" " ..lb.prompt())

if gmcp.Char and gmcp.Char.Status and gmcp.Char.Vitals and gmcp.Char.Vitals.charstats and (gmcp.Char.Status.class == "Runewarden" or gmcp.Char.Status.class == "Infernal") and (gmcp.Char.Vitals.charstats[3] == "Spec: Dual Blunt" or gmcp.Char.Vitals.charstats[4] == "Spec: Dual Blunt") then
mymomentum = ataxia.vitals.class or 0
end

tarc.write()