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

-- Limb Counter Window — uses Adjustable.Container for drag/resize/position-save
tarc = tarc or {}

tarc.window = Adjustable.Container:new({
  name = "tarc.window",
  x = "0%", y = "-50%",
  width = "14%", height = "30.4%",
  adjLabelstyle = "background-color:rgba(0,0,0,100%); border: 1px solid #404040;",
  buttonstyle = [[
    QLabel{ border-radius: 4px; background-color: rgba(140,140,140,100%);}
    QLabel::hover{ background-color: rgba(160,160,160,100%);}
  ]],
  titleText = "Limb Counter",
  titleStyle = "color: gray; font-size: 8pt;",
  lockStyle = "border: 1px solid #404040;",
}, main)
tarc.window:changeMenuStyle("dark")

tarc.container = Geyser.Container:new({
  name = "tarc.back",
  x = 0, y = 0,
  width = "100%",
  height = "100%",
}, tarc.window)

tarc.console = Geyser.MiniConsole:new({
  name = 'tarc',
  color = 'black',
  x = '4', y = '4',
  width = '100%-8', height = '100%-8',
  fontSize = 12,
  font = "Bitstream Vera Sans Mono",
  autoWrap = true,
}, tarc.container)

tarc.window:show()

-- Forward tarc:cecho() and tarc:clear() to the console
function tarc:cecho(text) tarc.console:cecho(text) end
function tarc:clear() tarc.console:clear() end

-- ── HUD helpers: coloured text bars for vitals ─────────────────────────────
local BAR_W = 10
local function _clampPct(p)
  p = tonumber(p) or 0
  if p < 0 then return 0 elseif p > 100 then return 100 else return p end
end
-- health-style colour: green high, yellow mid, red low
local function _pctColour(p)
  if p >= 66 then return "green" elseif p >= 33 then return "yellow" else return "red" end
end
-- % from cur/max, nil-safe (nil when it can't be computed -> caller skips the row)
local function _pct(cur, max)
  cur, max = tonumber(cur), tonumber(max)
  if not (cur and max and max > 0) then return nil end
  return math.floor(cur / max * 100)
end
-- a coloured bar: filled portion in `colr` (default = health colour), rest dim
local function _bar(p, colr)
  p = _clampPct(p)
  local f = math.floor(p / 100 * BAR_W + 0.5)
  colr = colr or _pctColour(p)
  return "<" .. colr .. ">" .. string.rep("█", f) .. "<gray>" .. string.rep("░", BAR_W - f) .. "<reset>"
end
-- one labelled vital row: "HP  ██████░░░░  63%" (nil pct -> nil so the caller can skip)
local function _vitalRow(label, pct, colr)
  if pct == nil then return nil end
  pct = _clampPct(pct)
  colr = colr or _pctColour(pct)
  return string.format("   <white>%-4s<reset> ", label) .. _bar(pct, colr)
    .. string.format(" <%s>%3d%%<reset>", colr, pct)
end
-- integer with thousand separators: 9737013 -> "9,737,013"
local function _fmtNum(n)
  local s = string.format("%d", math.floor(tonumber(n) or 0))
  local sign = ""
  if s:sub(1, 1) == "-" then sign = "-"; s = s:sub(2) end
  s = s:reverse()
  s = s:gsub("(%d%d%d)", "%1,")
  s = s:reverse()
  s = s:gsub("^,", "")
  return sign .. s
end
-- Compact magnitude for narrow columns: 691 -> "691", 866964 -> "867k", 2193713 -> "2.2M".
-- The comma'd _fmtNum is right for a single headline figure but far too wide for a ten-row
-- table in a panel this narrow -- "866,964" alone is most of the available width.
--
-- Rounds rather than truncates: 866,964 is 867k, and flooring would under-report every row by
-- up to a thousand for no reason.
local function _fmtShort(n)
  n = math.floor(tonumber(n) or 0)
  if n >= 10000000 then return string.format("%dM", math.floor(n / 1000000 + 0.5)) end
  if n >= 1000000 then return string.format("%.1fM", n / 1000000) end
  if n >= 1000 then return string.format("%dk", math.floor(n / 1000 + 0.5)) end
  return tostring(n)
end

-- seconds -> compact duration: "45s", "8m03s", "1h02m"
local function _fmtTime(sec)
  sec = math.floor(tonumber(sec) or 0)
  if sec < 60 then return sec .. "s" end
  local m = math.floor(sec / 60)
  if m < 60 then return string.format("%dm%02ds", m, sec % 60) end
  return string.format("%dh%02dm", math.floor(m / 60), m % 60)
end

function tarc.write()
  tarc:clear()
  
  --if target and target ~= "" and target ~= "None" and target ~= "none" and lb[target] then
  if target and target ~= "" and target ~= "None" and target ~= "none" then
   local _dz = ataxia.denizensHere
   local _tname = (type(target) == "number" and type(_dz) == "table" and _dz[target]) or nil
   if _tname then
     tarc:cecho("   <white>" .. _tname .. "<reset> <gray>#" .. target .. "<reset>\n")
   else
     tarc:cecho("   Target: " .. target .. "\n")
   end

    -- V3 Affliction Display (probability-based) -- PvP targets only; a denizen (numeric id) gets
    -- the clean bashing panel below instead of the lock/aff readout.
    if type(target) ~= "number" and affConfigV3 and affConfigV3.enabled then
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
    elseif type(target) ~= "number" and tAffsV2 then
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
      local v = ataxia.vitals or {}
      -- Our vitals as bars, read STRAIGHT from GMCP (Char.Vitals) so they're always the live
      -- values, never the derived ataxia.vitals copy. Nil-safe: skip any bar we can't compute.
      local gv = (gmcp.Char and gmcp.Char.Vitals) or {}
      local rowHP = _vitalRow("HP", _pct(gv.hp, gv.maxhp))
      -- MP sits directly under HP, the conventional vitals order. It keeps the SAME
      -- health-style colour ramp as the other rows rather than a flat mana-blue: on a
      -- combat HUD the useful signal is "this is getting dangerous", and running out of
      -- mana is a kill condition for us (Psion excise, the Kai Choke 250-mana floor)
      -- just as health is. A flat colour would show the number and hide the warning.
      local rowMP = _vitalRow("MP", _pct(gv.mp, gv.maxmp))
      local rowWP = _vitalRow("WP", _pct(gv.wp, gv.maxwp))
      local rowEP = _vitalRow("EP", _pct(gv.ep, gv.maxep))
      if rowHP then tarc:cecho(rowHP .. "\n") end
      if rowMP then tarc:cecho(rowMP .. "\n") end
      if rowWP then tarc:cecho(rowWP .. "\n") end
      if rowEP then tarc:cecho(rowEP .. "\n") end
      -- Rage (charstats-parsed into ataxia.vitals) + XP-to-level (GMCP nl), one compact line
      tarc:cecho(string.format("   <white>Rage<reset> <orange>%s<reset>", tostring(v.rage or 0)))
      if gv.nl then tarc:cecho(string.format("    <white>XP<reset> <cyan>%s%%<reset>", tostring(gv.nl))) end
      tarc:cecho("\n")
      -- Class-specific resource (willpower is already the WP bar above)
      if gmcp.Char.Status.class == "Shaman" then
        tarc:cecho("   <white>SwiftC<reset> <cyan>" .. tostring(curseCharge or 0) .. "<reset>\n")
      elseif gmcp.Char.Status.class == "Pariah" then
        tarc:cecho("   <white>Epitaph<reset> <cyan>" .. tostring(v.epitaph or 0) .. "<reset>\n")
      elseif gmcp.Char.Status.class == "Infernal" then
        -- Life essence is the Necromancy resource TYRANNY spends (3% a summon), so it
        -- belongs on the panel where the cost is visible before it is paid. Hyena maul
        -- readiness sits beside it -- it is a free hit we otherwise only learn about by
        -- watching the combat spam.
        local ess = tonumber(v.essence)
        if ess then
          local eCol = (ess < 20 and "red") or (ess < 50 and "yellow") or "green"
          tarc:cecho(string.format("   <white>Essence<reset> <%s>%d%%<reset>", eCol, ess))
        else
          tarc:cecho("   <white>Essence<reset> <DimGrey>??<reset>")
        end
        tarc:cecho(string.format("   <white>Maul<reset> %s\n",
          ataxiaBasher.hyenaMaulReady and "<green>ready<reset>" or "<DimGrey>cd<reset>"))
        if infArmyOfDead or infDaemonJaws then
          local bits = {}
          if infArmyOfDead then bits[#bits + 1] = "<cyan>Army of the Dead<reset>" end
          if infDaemonJaws then bits[#bits + 1] = "<cyan>Daemon Jaws<reset>" end
          tarc:cecho("   " .. table.concat(bits, " <gray>|<reset> ") .. "\n")
        end
      elseif gmcp.Char.Status.class == "Depthswalker" then
        -- Age + word balance are the two DW resources the basher actually spends, and
        -- the buff chips answer "am I getting my damage?" at a glance: green = standing,
        -- grey = down, RED = down while a boon is paying us to have it up.
        local dw = (ataxiaTables and ataxiaTables.depthswalker) or {}
        local age = tonumber(dw.age) or 0
        local ageCol = "DimGrey"
        if age > 600 then ageCol = "red"
        elseif age > 400 then ageCol = "orange"
        elseif age > 250 then ageCol = "yellow" end
        tarc:cecho(string.format("   <white>Age<reset> <%s>%d<reset>   <white>Word<reset> %s\n",
          ageCol, age,
          (dw.wordBal == false) and "<DimGrey>spent<reset>" or "<green>ready<reset>"))

        local defs = ataxia.defences or {}
        -- Blur is ordinary upkeep normally, but Flashforward pays +20% damage for it --
        -- so when that boon is claimed and blur is DOWN, shout about it.
        local chips = {
          { label = "Blur", def = "blur", boon = dwFlashforward },
          { label = "Trusad", def = "precision" },
          { label = "Tsuura", def = "durability" },
          { label = "Mainaas", def = "bodyaugment" },
        }
        local line = "   "
        for _, c in ipairs(chips) do
          local col = defs[c.def] and "green" or (c.boon and "red" or "DimGrey")
          line = line .. "<" .. col .. ">" .. c.label .. "<reset> "
        end
        tarc:cecho(line .. "\n")
        if dwFlashforward then
          tarc:cecho("   <cyan>Flashforward<reset> <gray>+20% dmg while Blur<reset>\n")
        end
      end
      if bashStats and bashStats_getDPS then
        if not bashStats.totalDamage then bashStats.totalDamage = 0 end
        if not bashStats.damageByType then bashStats.damageByType = {} end
        if not bashStats.dpsSessionStart then bashStats.dpsSessionStart = getEpoch() end
        if not bashStats.lastBalanceTime then bashStats.lastBalanceTime = 0 end
        if not bashStats.lastBalanceDamage then bashStats.lastBalanceDamage = 0 end
        if not bashStats.currentBalanceDamage then bashStats.currentBalanceDamage = 0 end
        local sDPS, bDPS = bashStats_getDPS()
        tarc:cecho("\n   <cyan>── DPS ──────────<reset>\n")
        -- "Now" is a rolling 10s window and "Avg" is per ACTIVE combat second (v4.7.207) --
        -- not one balance sample and not wall-clock. The labels say which, because the two
        -- numbers now mean something different from what they used to, and a stale reading of
        -- either is worse than no reading.
        tarc:cecho(string.format("   <white>Now  <reset> <cyan>%s<reset>/s <gray>10s<reset>\n", tostring(bDPS)))
        tarc:cecho(string.format("   <white>Avg  <reset> <yellow>%s<reset>/s <gray>fighting<reset>\n", tostring(sDPS)))
        tarc:cecho(string.format("   <white>Total<reset> <green>%s<reset>\n", _fmtNum(bashStats.totalDamage)))

        -- What is actually hurting us this session. The most useful part is WHICH TYPE, not
        -- how much: it is what picks the resistance paragon, the Blademaster infuse to keep
        -- up, and which curing priorities matter -- and it is invisible in the scroll, where
        -- every "Health lost" line is one of hundreds.
        if bashStats_topIncoming then
          -- TOP N BY TYPE (user request 2026-08-04: "should be tracking at least top 10").
          -- One line each, compact magnitudes. The single worst offender only tells you what
          -- to armour against; the SHAPE of the list tells you whether one thing dominates
          -- (worth a resistance paragon) or the damage is spread across five types, where no
          -- single resistance helps and the answer is to kill faster or take fewer rounds.
          -- That distinction is invisible when only the leader is shown.
          local ranked = bashStats_incomingRanked and bashStats_incomingRanked() or {}
          if #ranked > 0 then
            local total = bashStats.incomingTotal or 0
            local top = tonumber(ataxiaBasher and ataxiaBasher.takenTop) or 10
            tarc:cecho("\n   <cyan>── Taken ────────<reset>\n")
            tarc:cecho(string.format("   <gray>total<reset> <indian_red>%s<reset>  <gray>%s hits<reset>\n",
              _fmtNum(total), _fmtNum(bashStats.incomingHits or 0)))
            -- Only rows that exist: early in a session this is one or two lines, not ten blanks.
            for i = 1, math.min(top, #ranked) do
              local dtype, amt = ranked[i][1], ranked[i][2]
              local pct = (total > 0) and math.floor((amt / total) * 100 + 0.5) or 0
              -- Names run to ~16 chars ("physical cutting"); clip rather than wrap, since a
              -- wrapped row would break the column alignment the table exists for.
              if #dtype > 16 then dtype = dtype:sub(1, 15) .. "." end
              tarc:cecho(string.format("   <white>%-16s<reset> <indian_red>%5s<reset> <gray>%2d%%<reset>\n",
                dtype, _fmtShort(amt), pct))
            end
            if #ranked > top then
              tarc:cecho(string.format("   <gray>+%d more<reset>\n", #ranked - top))
            end
          end
        end

        -- Session summary (kills / crits / gold / time + kills-per-hour)
        local elapsed = getEpoch() - (bashStats.dpsSessionStart or getEpoch())
        local kph = (elapsed > 60) and math.floor((bashStats.slain or 0) / elapsed * 3600) or 0
        tarc:cecho("\n   <cyan>── Session ──────<reset>\n")
        tarc:cecho(string.format("   <white>Kills<reset> <green>%s<reset>   <white>Crits<reset> <yellow>%s<reset>\n",
          _fmtNum(bashStats.slain or 0), _fmtNum(bashStats.crits or 0)))
        tarc:cecho(string.format("   <white>Gold <reset> <yellow>%s<reset>\n", _fmtNum(bashStats.gainedGold or 0)))
        tarc:cecho(string.format("   <white>Time <reset> <cyan>%s<reset>  <gray>%s/h<reset>\n", _fmtTime(elapsed), tostring(kph)))
      end
      -- Mob damage records for current target
      if secondTarget and secondTarget ~= "" and ataxia.data and ataxia.data.db and ataxia.data.db.mobdmgdb then
        local class = gmcp.Char.Status.class or ""
        local statName, statValue = ataxia.data.db.getPrimaryStat()
        local stat = statName .. " " .. statValue
        local rows = db:fetch(ataxia.data.db.mobdmgdb.hits,
          db:AND(
            db:eq(ataxia.data.db.mobdmgdb.hits.class, class),
            db:eq(ataxia.data.db.mobdmgdb.hits.stat, stat),
            db:eq(ataxia.data.db.mobdmgdb.hits.mob, secondTarget)
          )
        )
        if rows and #rows > 0 then
          local row = rows[1]
          tarc:cecho("\n   <cyan>── Mob Dmg ──────<reset>\n")
          tarc:cecho("   <white>Min:  <yellow>" .. row.min_damage .. "<reset>\n")
          tarc:cecho("   <white>Max:  <green>" .. row.max_damage .. "<reset>\n")
          tarc:cecho("   <white>Hits: <purple>" .. row.hit_count .. "<reset>\n")
        end
      end
    end
  
   else 
    tarc:cecho("   Target: Sartan\n\n")
   end
   if ataxiaNDB.players[target] and lb and lb[target] and lb[target].hits then
    tarc:cecho("   Limb Counter\n")
    for _, ln in ipairs({"head", "torso", "left arm", "right arm", "left leg", "right leg"}) do
      tarc:cecho(string.format("%11s", ln) .. ": " .. (lb[target].hits[ln] or 0) .. "\n")
    end
    end
    if gmcp.Char and gmcp.Char.Status and gmcp.Char.Status.class == "Monk" then
    tarc:cecho(string.format("\n   <white>Kai<reset> <cyan>%s<reset>   <white>Kata<reset> <cyan>%s<reset>\n",
      tostring(ataxia.vitals.class or 0), tostring(katachain or 0)))
    local flabel = ataxia.vitals.form and "Form" or "Stance"
    local fval = ataxia.vitals.form or ataxia.vitals.stance or "unknown"
    tarc:cecho(string.format("   <white>%s<reset> <cyan>%s<reset>\n", flabel, tostring(fval)))
    end
    if gmcp.Char and gmcp.Char.Status and gmcp.Char.Status.class == "Blademaster" then
    local shin = blademaster and blademaster.getShin and blademaster.getShin() or (ataxia.vitals.class or 0)
    tarc:cecho(string.format("\n   <white>Shin<reset> <cyan>%s<reset>", tostring(shin)))
    if ataxia.vitals.stance then
      tarc:cecho(string.format("   <white>Stance<reset> <cyan>%s<reset>", tostring(ataxia.vitals.stance)))
    end
    tarc:cecho("\n")
    end
    if gmcp.Char and gmcp.Char.Status and (gmcp.Char.Status.class == "Runewarden" or gmcp.Char.Status.class == "Infernal") and ataxia.vitals and ataxia.vitals.knight == "Dual Blunt" then
    tarc:cecho(string.format("\n   <white>Momentum<reset> <cyan>%s<reset>\n", tostring(mymomentum or 0)))
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
        tarc:cecho("\n   <yellow>Denizens (" .. count .. ")<reset>\n")
        for id, name in pairs(ataxia.denizensHere) do
          if id == target then
            tarc:cecho("   <green>> " .. name .. "<reset>\n")   -- current target
          else
            tarc:cecho("     <gray>" .. name .. "<reset>\n")
          end
        end
      end
    end

    -- Players in Area (mindnet)
    if ataxia.playersInArea and #ataxia.playersInArea > 0 then
      tarc:cecho("\n   <magenta>Players in Area:<reset>\n")
      for _, player in ipairs(ataxia.playersInArea) do
        local color = "white"
        if ataxiaNDB_getColour then color = ataxiaNDB_getColour(player) or "white" end
        tarc:cecho("     <" .. color .. ">" .. player .. "<reset>\n")
      end
    end

    -- Mob health bar, anchored at the BOTTOM of the panel. Data: denizen-state hpp (fed
    -- each prompt from gmcp.IRE.Target.Info by 010_Prompt_Running, id-guarded) with a
    -- live-GMCP fallback for a fresh target the prompt hasn't fed yet. hpperc "-1" / a
    -- negative hpp means "no live reading" (dead or no server target), not 0% -- render
    -- the row as "??" then, never hide it: an always-?? bar is the visible symptom that
    -- the server target isn't set (settarget) and hp data isn't streaming.
    if ataxiaBasher and ataxiaBasher.enabled and type(target) == "number" then
      local mobPct
      if ataxiaBasher_dsGet then
        local ds = ataxiaBasher_dsGet(target)
        if ds and ds.hpp and ds.hpp >= 0 then mobPct = ds.hpp end
      end
      if not mobPct and gmcp.IRE and gmcp.IRE.Target and gmcp.IRE.Target.Info
         and gmcp.IRE.Target.Info.hpperc then
        local raw = tostring(gmcp.IRE.Target.Info.hpperc):gsub("%%", "")
        if raw ~= "-1" then mobPct = raw end
      end
      tarc:cecho("\n")
      if mobPct then
        tarc:cecho(_vitalRow("Mob", _clampPct(mobPct)) .. "\n")
      else
        tarc:cecho("   <white>Mob <reset> <gray>" .. string.rep("░", BAR_W) .. "  ??<reset>\n")
      end
    end

end

-- Refresh the HUD on room/target changes AND on live target-info pushes: the server sends
-- gmcp.IRE.Target.Info (with the mob's hpperc) each combat round -- it's what we compose the
-- prompt's |(id|hp%)| from -- so refreshing on it makes the Mob bar track the fight live, not
-- just jump on room changes. Wrappers call the current tarc.write (late-bound via the persistent
-- tarc table); the flag stops handlers stacking up each time this file re-sources on a reload.
if not tarc._refreshHandlers then
  tarc._refreshHandlers = true
  registerAnonymousEventHandler("targets updated", function() tarc.write() end)
  registerAnonymousEventHandler("gmcp.IRE.Target.Info", function() tarc.write() end)
end