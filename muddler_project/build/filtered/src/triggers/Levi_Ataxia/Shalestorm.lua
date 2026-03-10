local line = matches[1]

-- Shalestorm start
if line:find("call upon the might of Elemental Earth to grind down") then
  local tgt = matches[2]
  if tgt == target then
    magi.offense.state.shalestorm = true
    magi.offense.ptRelay(target .. ": Shalestorm started")
    magi.offense.debugEcho("Shalestorm active on " .. target)
  end

-- Shalestorm limb break
elseif line:find("boulders smashes into the") then
  local limb = matches[2]
  local tgt = matches[3]
  if tgt == target and limb then
    local limbName = limb:lower():gsub("%s+", "")
    tarAffed("broken" .. limbName)
    magi.offense.ptRelay(target .. ": Shalestorm (broken " .. limb .. ")")
  end

-- Shalestorm shield snap
elseif line:find("shattering it in a spray of translucent shards") then
  local tgt = matches[2]
  if tgt == target then
    erAff("shield")
    magi.offense.debugEcho("Shalestorm broke " .. target .. "'s shield")
    raiseEvent("offense update")
  end

-- Shalestorm end
elseif line:find("can no longer maintain your shalestorm") then
  local tgt = matches[2]
  -- Anti-illusion guard: if earth resonance > 0, shalestorm is still active
  if magi.resonance and magi.resonance.earth > 0 then
    magi.offense.debugEcho("Shalestorm end message ignored (earth resonance still active)")
    return
  end
  if tgt == target then
    magi.offense.state.shalestorm = false
    magi.offense.debugEcho("Shalestorm ended on " .. target)
    raiseEvent("offense update")
  end
end
