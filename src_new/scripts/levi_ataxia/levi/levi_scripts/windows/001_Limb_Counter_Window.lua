--[[mudlet
type: script
name: Limb Counter Window
hierarchy:
- Levi_Ataxia
- LEVI
- Levi  Scripts
- Leviticus
- Windows
attributes:
  isActive: 'yes'
  isFolder: 'no'
packageName: ''
]]--

--[[mudlet
type: script
name: Limb Counter Window
hierarchy:
- Levi_Ataxia
- LEVI
- Levi  Scripts
- Leviticus
- Windows
attributes:
  isActive: 'yes'
  isFolder: 'no'
packageName: ''
]]--

tarcLabel = Geyser.Label:new({
  name = "tarcLabel",
  x = "0%", y = "-50%",
  width = "14%", height = "30.4%",
})

tarcLabel:setStyleSheet([[
  border: 1px solid #404040;
]])

tarc = Geyser.MiniConsole:new({
  name='tarc',
  color='black',
  x='16', y='20',
  width = '100%-20', height = '100%-30',
  fontSize = 12,
  font = "Bitstream Vera Sans Mono",
  autoWrap = true
}, tarcLabel)

function tarc.write()
  tarc:clear()
  
  --if target and target ~= "" and target ~= "None" and target ~= "none" and lb[target] then
  if target and target ~= "" and target ~= "None" and target ~= "none" then
   tarc:cecho("   Target: " .. target .. "\n")

    -- V3 Affliction Display (probability-based)
    if affConfigV3 and affConfigV3.enabled then
      local lockAffs = {"anorexia", "slickness", "asthma", "paralysis"}
      local shortNames = {
        anorexia = "ANO", slickness = "SLI", asthma = "AST", paralysis = "PAR",
        clumsiness = "CLU", nausea = "NAU", weariness = "WEA", stupidity = "STU",
        sensitivity = "SEN", healthleech = "HLE", haemophilia = "HAE",
        addiction = "ADD", impatience = "IMP", rebounding = "REB", shield = "SHD",
        prone = "PRONE", confusion = "CON", dementia = "DEM", paranoia = "PNO",
        hallucinations = "HAL", dizziness = "DIZ", epilepsy = "EPI", recklessness = "REC",
        shyness = "SHY", lethargy = "LET", darkshade = "DAR",
      }

      -- Show lock probability
      local lockProb = getStateProbabilityV3(lockAffs)
      local affStr = "   "
      if lockProb >= 0.9 then
        affStr = affStr .. "<green>[LOCK:" .. math.floor(lockProb * 100) .. "%]<reset> "
      elseif lockProb >= 0.3 then
        affStr = affStr .. "<yellow>[LOCK:" .. math.floor(lockProb * 100) .. "%]<reset> "
      end

      -- Show individual affs with probabilities
      local allProbs = getAllAffProbabilitiesV3()
      local sorted = {}
      local ignoreAffs = {curseward = true, blindness = true, deafness = true}
      for aff, prob in pairs(allProbs) do
        if prob >= 0.5 and not ignoreAffs[aff] then  -- Only show when likely present (50%+)
          table.insert(sorted, {aff = aff, prob = prob})
        end
      end
      table.sort(sorted, function(a, b) return a.prob > b.prob end)

      for _, entry in ipairs(sorted) do
        local aff, prob = entry.aff, entry.prob
        local shortName = shortNames[aff] or string.sub(aff, 1, 3):upper()

        -- Color based on probability (same for all afflictions including lock affs)
        local color = "orange"
        if prob >= 0.9 then color = "green"       -- 90%+ = stuck
        elseif prob >= 0.6 then color = "yellow"  -- 60-89% = likely
        end                                       -- 50-59% = orange (default)

        -- Format: "AST:67" or "AST" for 100%
        local display = shortName
        if prob < 1.0 then
          display = shortName .. ":" .. math.floor(prob * 100)
        end
        affStr = affStr .. "<" .. color .. ">" .. display .. "<reset> "
      end

      tarc:cecho(affStr .. "\n")
      tarc:cecho("   <gray>[V3: " .. #afflictionStatesV3 .. " branches]<reset>\n")

    -- V2 Affliction Display (binary system - fallback)
    elseif tAffsV2 then
      local lockAffs = {"anorexia", "slickness", "asthma", "paralysis", "stupidity"}
      local shortNames = {
        anorexia = "ANO", slickness = "SLI", asthma = "AST", paralysis = "PAR", stupidity = "STU",
        nausea = "nau", clumsiness = "clu", weariness = "WEA", impatience = "IMP", confusion = "con",
        dementia = "dem", paranoia = "pnoia", hallucinations = "hal", dizziness = "diz", epilepsy = "epi",
        recklessness = "rec", shyness = "shy", prone = "PRONE", sensitivity = "sen", healthleech = "hleech",
        haemophilia = "hae", lethargy = "let", darkshade = "dar", addiction = "add", rebounding = "REB", shield = "SHD",
      }

      local lockCount = 0
      for _, aff in ipairs(lockAffs) do
        if tAffsV2[aff] then
          lockCount = lockCount + 1
        end
      end

      local affStr = "   "
      if lockCount >= 5 then
        affStr = affStr .. "<green>[LOCK]<reset> "
      elseif lockCount >= 1 then
        affStr = affStr .. "<yellow>[" .. lockCount .. "/5]<reset> "
      end

      local ignoreAffs = {curseward = true, blindness = true, deafness = true}
      for aff, present in pairs(tAffsV2) do
        if present and not ignoreAffs[aff] then
          -- Color: cyan=stacked, red=lock, white=other
          local color = "white"
          local stackCount = getStackCountV2 and getStackCountV2(aff) or 0
          if stackCount >= 2 then
            color = "cyan"
          else
            for _, la in ipairs(lockAffs) do
              if aff == la then color = "red" break end
            end
          end
          -- Display: add xN for stacked afflictions
          local shortName = shortNames[aff] or string.sub(aff, 1, 3)
          local display = shortName
          if stackCount >= 2 then
            display = shortName .. "x" .. stackCount
          end
          affStr = affStr .. "<" .. color .. ">" .. display .. "<reset> "
        end
      end

      tarc:cecho(affStr .. "\n")
    end
    tarc:cecho("\n")

    if ataxiaBasher.enabled then
      tarc:cecho("   Mob Health: " .. gmcp.IRE.Target.Info.hpperc .. "\n")
      tarc:cecho("   BattleR:    " ..ataxia.vitals.rage.. "\n")
      tarc:cecho("   Our Health: "..ataxia.vitals.hp..  "\n")
      tarc:cecho("   Our Willpo: "..ataxia.vitals.wp..  "\n")
      tarc:cecho("   Our Endur:  "..ataxia.vitals.ep..  "\n")
      tarc:cecho("   Our EXP:    "..ataxia.vitals.xp..  "\n")
      if gmcp.Char.Status.class == "Magi" or gmcp.Char.Status.class == "Blue Dragon" then
      tarc:cecho("   Our Willpow: "..ataxia.vitals.wp..  "\n")
      elseif gmcp.Char.Status.class == "Shaman" then
      tarc:cecho("   Our SwiftC: " ..curseCharge.."\n")     
      elseif gmcp.Char.Status.class == "Pariah" then
      tarc:cecho("Our Epitaph Number: "..ataxia.vitals.epitaph..  "\n")
      end
    end
  
   else 
    tarc:cecho("   Target: Sartan\n\n")
   end
   if ataxiaNDB.players[target] then
    tarc:cecho("   Limb Counter\n")
    for _, ln in ipairs({"head", "torso", "left arm", "right arm", "left leg", "right leg"}) do 
      tarc:cecho(string.format("%11s", ln) .. ": " .. lb[target].hits[ln] .. "\n")
    end
    end
    if gmcp.Char.Status.class == "Monk" then
    tarc:cecho("          Kai: " .. (ataxia.vitals.class or 0))
    tarc:cecho("\n         Kata: " .. (katachain or 0) .. "")
      if ataxia.vitals.form then
        tarc:cecho("\n       Form: " .. ataxia.vitals.form .. "\n")
      elseif ataxia.vitals.stance then
        tarc:cecho("\n       Stance: " .. ataxia.vitals.stance .. "\n")
      else
        tarc:cecho("\n       Stance: unknown\n")
      end
    end
    if gmcp.Char.Status.class == "Blademaster" then
    tarc:cecho("     Shin: " ..bmshin.. "\n\n")
    end
    if (gmcp.Char.Status.class == "Runewarden" or gmcp.Char.Status.class == "Infernal") and gmcp.Char.Vitals.charstats[3] == "Spec: Dual Blunt" or gmcp.Char.Vitals.charstats[4] == "Spec: Dual Blunt"  then 
    tarc:cecho("\n      Momentum: " ..mymomentum.. "\n\n")
    end
    --if ataxiaNDB.players[target] then
     --tarc:cecho(" Self Limb Counter\n")
      --for _, y in ipairs({"head", "torso", "left arm", "right arm", "left leg", "right leg"}) do
       --tarc:cecho(string.format("%11s", y) .. ": " .. slc.percentages[y] .. "\n")

      --end
    --end

    -- Players in Room
    if ataxia.playersHere and #ataxia.playersHere > 0 then
      tarc:cecho("\n   <cyan>Players Here:<reset>\n")
      for _, player in ipairs(ataxia.playersHere) do
        tarc:cecho("     " .. player .. "\n")
      end
    end

    -- Denizens in Room (only when basher enabled)
    if ataxiaBasher and ataxiaBasher.enabled and ataxia.denizensHere then
      local count = 0
      for _ in pairs(ataxia.denizensHere) do count = count + 1 end
      if count > 0 then
        tarc:cecho("\n   <yellow>Denizens Here:<reset>\n")
        for id, name in pairs(ataxia.denizensHere) do
          tarc:cecho("     " .. name .. "\n")
        end
      end
    end

end

-- Register for room content updates
registerAnonymousEventHandler("targets updated", tarc.write)