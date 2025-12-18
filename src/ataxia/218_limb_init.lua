-- unnamed > For Levi > Levi_062424 > leviticus > LeviAtaxia > Levi  Scripts > Leviticus > limb.1.2 > Limb > limb init

lb = lb or {}

function lb.initTarget(name)
  name = name:lower():title()
  
  lb[name] = lb[name] or {}
  lb[name].t = lb[name].t or {}
  lb[name].hits = lb[name].hits or {
    head = 0,
    torso = 0,
    ["left arm"] = 0,
    ["right arm"] = 0,
    ["left leg"] = 0,
    ["right leg"] = 0,
  }
  
  raiseEvent("limb hits updated", name, "all")
end

function lb.echo(str)
  cecho("<turquoise>[Limb]: <white>" .. str .. "\n")
end