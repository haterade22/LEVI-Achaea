-- unnamed > For Levi > Levi_062424 > leviticus > LeviAtaxia > Levi  Scripts > Leviticus > limb.1.2 > Limb > limb management

function lb.addHit(name, ltar, amount)
  name = name:lower():title()
  if not lb[name] then lb.initTarget(name) end
  if not lb[name].hits[ltar] then 
    cecho("<red>(!) Limb not found: " .. tostring(ltar) .. ".\n")
    return
  end
  lb[name].hits[ltar] = lb[name].hits[ltar] + amount
  if lb[name].t[ltar] then killTimer(lb[name].t[ltar]) end
  lb[name].t[ltar] = tempTimer(180, [[
    lb.resetLimb("]] .. name .. [[", "]] .. ltar .. [[")
    lb["]] .. name .. [["].t["]] .. ltar .. [["] = nil
  ]])
  cecho(" " .. ((lb[name].hits[ltar] > 100 and "<firebrick>") or "<ansi_yellow>") .. "("
            .. ((lb[name].hits[ltar] > 100 and "<orange_red>") or "<yellow>") .. lb[name].hits[ltar] .. "%"
            .. ((lb[name].hits[ltar] > 100 and "<firebrick>") or "<ansi_yellow>") .. ")")    
  
if lb[name].hits[ltar] < 100 and (lb[name].hits[ltar] + mylimbattackpercentage) >= 100 then
singleHitPrepped = true
elseif lb[name].hits[ltar] < 100 and (lb[name].hits[ltar] + mylimbattackpercentage) < 100 then
singleHitPrepped = false
elseif lb[name].hits[ltar] < 100 and (lb[name].hits[ltar] + 2*mylimbattackpercentage) > 100 then 
dualHitPrepped = true
elseif lb[name].hits[ltar] < 100 and (lb[name].hits[ltar] + 2*mylimbattackpercentage) < 100 then 
dualHitPrepped = false
end
  
  raiseEvent("limb hits updated", name, ltar, amount)
  


end

function lb.resetLimb(name, ltar)
  name = name:lower():title()
  if not lb[name].hits[ltar] then
    cecho("<red>(!) Limb not found: " .. tostring(ltar) .. ".\n")
    return
  end
  lb[name].hits[ltar] = 0
  lb.echo("Reset " .. name .. ((name:sub(-1) == "s" and "'") or "'s") .. " " .. ltar .. ".")
end

function lb.salve(name, area)
  lb[name].t.cure = tempTimer(3.7, [[
    local convert = {
      head = {"head"},
      torso = {"torso"},
      arms = {[1] = "left arm", [2] = "right arm"},
      legs = {[1] = "left leg", [2] = "right leg"},
    }
    if not convert["]] .. area .. [["] then return end
    for _, ltar in ipairs(convert["]] .. area .. [["]) do 
      if lb["]] .. name .. [["].hits[ltar] >= 100 then 
        if lb["]] .. name .. [["].t.cure then killTimer(lb["]] .. name .. [["].t.cure) end
        lb.resetLimb("]] .. name .. [[", ltar, true)
        if lb["]] .. name .. [["].t[ltar] then
          killTimer(lb["]] .. name .. [["].t[ltar])
          lb["]] .. name .. [["].t[ltar] = nil
        end
        lb["]] .. name .. [["].t.cure = nil
        break
      end
    end
  ]])
end

function lb.resetAll(name)
  for _, v in ipairs({"head", "torso", "left arm", "right arm", "left leg", "right leg"}) do 
    if lb[name] then
      if lb[name].hits[v] > 0 then 
        lb.resetLimb(name, v)
      end
      if lb[name].t[v] then 
        killTimer(lb[name].t[v])
        lb[name].t[v] = nil
      end
    end
  end
end