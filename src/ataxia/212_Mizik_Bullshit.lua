-- unnamed > For Levi > Levi_062424 > leviticus > LeviAtaxia > Levi  Scripts > Leviticus > Mage > Mizik Bullshit

function MagiFire()
  local actions = {}
  local addAction = function(action)
    table.insert(actions, action)
  end

  if not Legacy.Curing.Affs.retardation then
    addAction("stand")
    addAction("get body from vault zephariel")
    addAction("wield shield442968 staff324970")
  end
  
  --If target has a shield, remove it
  if ak.defs.shield then
    addAction("cast erode at " .. target .. " shield")
  -- If target has 25 percent health, Stormhammer
  elseif targetHealth <= 25 then
    addAction("cast stormhammer at " .. target)
  -- If burning is 2 or greater and conflagrate is true than stack burning
  elseif affstrack.score.aflame >= 200 and affstrack.score.conflagrate == 100 then
        --If I have ashbeast and target is 40 percent or below, kill
      if targetHealth <= 40 and ashbeast == true then
        addAction("elemental destroy " .. target)
        -- If fire is 0 than Firelash to get Fire up
      elseif magi.resonance.fire == 0 then
        addAction("cast firelash at " .. target)
        -- If fire is 3 than emanation for 2 burning
      elseif magi.resonance.fire == 3 then
        addAction("cast emanation at " .. target .. " fire")
        -- If target has weariness than cast dehydrate at them for burning
      elseif affstrack.score.weariness > 67 then
        addAction("cast dehydrate at " ..target)  
        --If none of the above are true than magma 
      else
        addAction("cast magma at " .. target)
      end
  --if I have burning at 2 and fire and air at 2 than conflagrate
  elseif affstrack.score.aflame >= 200 and affstrack.score.conflagrate < 100 and magi.resonance.fire >= 2 and magi.resonance.air >= 2 then
    addAction("cast conflagrate at " ..target)
  --if I dont cast fulminate to get air and fire
  elseif affstrack.score.aflame >= 200 and affstrack.score.conflagrate < 100 and magi.resonance.fire < 2 and magi.resonance.air < 2 then
    addAction("cast fulminate at " ..target)
  --if I dont have magi.firestorm than get it
  elseif not magi.firestorm then
    if magi.resonance.air >= 2 and magi.resonance.fire >= 2 then
      addAction("cast firestorm")
    else
      addAction("cast fulminate at " .. target)
    end
  -- Get burning on target
  --Get scalded
  elseif affstrack.score.scalded < 100 then
    addAction("cast magma at " ..target)
  -- Stack Burning with Dehydrate
  elseif affstrack.score.aflame < 200 then
    addAction("cast dehydrate at " ..target)
  
end  
 
 
  local commandSequence = table.concat(actions, "|")
  if Legacy.Curing.Affs.retardation then
    send(commandSequence, false)
  else
    send("queue addclear free " .. commandSequence .. "|assess " .. target)
  end
end
