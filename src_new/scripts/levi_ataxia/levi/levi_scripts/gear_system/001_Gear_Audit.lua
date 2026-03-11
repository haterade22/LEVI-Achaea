--[[mudlet
type: script
name: Gear Audit
hierarchy:
- Levi_Ataxia
- LEVI
- Levi  Scripts
- Gear System
attributes:
  isActive: 'yes'
  isFolder: 'no'
packageName: ''
]]--

-- Gear Audit System for Achaea
-- Automates GEAR LIST ALL + GEAR PROBE to collect Set, Slot, and Effects
-- Usage: gearaudit [start|stop|show|set <name>|slot <slot>|effect <keyword>|save|load|help]

--------------------------------------------------------------------------------
-- NAMESPACE AND CONFIGURATION
--------------------------------------------------------------------------------

gearAudit = gearAudit or {}

gearAudit.state = {
  phase = "IDLE",           -- IDLE, LISTING, PROBING, COMPLETE
  triggers = {},            -- Store trigger IDs for cleanup
  timers = {},              -- Store timer IDs for cleanup
  probeQueue = {},          -- Queue of gear IDs to probe
  currentProbeIndex = 0,
  currentProbeId = nil,
  capturingEffects = false,
  currentEffects = {},
  effectDashCount = 0,      -- Track dashed lines in effects section (0=before first, 1=after first/capturing, 2=done)
  listingComplete = false,
}

gearAudit.data = {}         -- Main storage: keyed by gear ID

gearAudit.config = {
  probeDelay = 0.7,         -- Delay between probes (seconds)
  saveFile = "gearaudit",   -- Save file name
  timeout = 300,            -- Timeout in seconds (5 minutes for large inventories)
  bisWeights = {
    addDmgPct       = 10.0,  -- +X% damage (best PvE stat)
    celerity         = 8.0,  -- attack speed
    burstEffective   = 7.0,  -- burst dmg normalized to per-attack value
    ignorePct        = 6.0,  -- ignore denizen resistance
    hpPct            = 3.0,  -- HP increase
    hpRegenPct       = 2.5,  -- HP regen
    dmgReductionPct  = 2.0,  -- damage reduction
    resistPct        = 1.5,  -- resistance
    wpRegenPct       = 1.0,  -- WP regen
    blackoutPct      = 1.0,  -- blackout reduction
    conditionalMult  = 0.5,  -- location-locked gear discounted 50%
    brMult           = 0.7,  -- battlerage-conditional discounted 30%
  },
  keepPerSet = 3,             -- Keep top N items per slot per set, scrap the rest
}

--------------------------------------------------------------------------------
-- UTILITY FUNCTIONS
--------------------------------------------------------------------------------

function gearAudit.echo(text)
  cecho("\n<dark_orchid>[<light_slate_blue>GearAudit<dark_orchid>]<lavender>: <plum>" .. text)
end

function gearAudit.status()
  local count = 0
  for _ in pairs(gearAudit.data) do count = count + 1 end
  gearAudit.echo("Phase: " .. gearAudit.state.phase ..
                 " | Gear items: " .. count ..
                 " | Queue: " .. #gearAudit.state.probeQueue ..
                 " | Progress: " .. gearAudit.state.currentProbeIndex .. "/" .. #gearAudit.state.probeQueue)
end

--------------------------------------------------------------------------------
-- INITIALIZATION AND CLEANUP
--------------------------------------------------------------------------------

function gearAudit.init()
  gearAudit.state.phase = "IDLE"
  gearAudit.state.triggers = {}
  gearAudit.state.timers = {}
  gearAudit.state.probeQueue = {}
  gearAudit.state.currentProbeIndex = 0
  gearAudit.state.currentProbeId = nil
  gearAudit.state.capturingEffects = false
  gearAudit.state.currentEffects = {}
  gearAudit.state.effectDashCount = 0
  gearAudit.state.listingComplete = false
end

function gearAudit.cleanup()
  -- Kill all triggers
  for _, trigId in ipairs(gearAudit.state.triggers) do
    if killTrigger then killTrigger(trigId) end
  end
  -- Kill all timers
  for _, timerId in ipairs(gearAudit.state.timers) do
    if killTimer then killTimer(timerId) end
  end
  gearAudit.state.triggers = {}
  gearAudit.state.timers = {}
end

--------------------------------------------------------------------------------
-- PERSISTENCE
--------------------------------------------------------------------------------

function gearAudit.save()
  local separator = package.config:sub(1, 1)
  local filepath = getMudletHomeDir() .. separator .. gearAudit.config.saveFile
  table.save(filepath, gearAudit.data)

  -- Profile backup (re-read from file to avoid circular ref issues)
  _ataxia_backup = _ataxia_backup or {}
  _ataxia_backup.gearaudit = {}
  table.load(filepath, _ataxia_backup.gearaudit)

  gearAudit.echo("Saved " .. gearAudit.tableSize(gearAudit.data) .. " gear items to disk.")
end

function gearAudit.load()
  local separator = package.config:sub(1, 1)
  local filepath = getMudletHomeDir() .. separator .. gearAudit.config.saveFile
  if io.exists(filepath) then
    gearAudit.data = {}
    table.load(filepath, gearAudit.data)
    gearAudit.echo("Loaded " .. gearAudit.tableSize(gearAudit.data) .. " gear items from disk.")
  elseif _ataxia_backup and _ataxia_backup.gearaudit then
    gearAudit.data = deepcopy(_ataxia_backup.gearaudit)
    gearAudit.echo("Loaded " .. gearAudit.tableSize(gearAudit.data) .. " gear items from profile backup.")
  else
    gearAudit.echo("No saved gear audit data found.")
  end
end

function gearAudit.tableSize(t)
  local count = 0
  for _ in pairs(t) do count = count + 1 end
  return count
end

--------------------------------------------------------------------------------
-- EFFECT SUMMARIZER - Parse effect text into concise summary
--------------------------------------------------------------------------------

function gearAudit.summarizeEffect(effects)
  if not effects or #effects == 0 then return "" end

  -- Combine all effect lines into one string for parsing
  local fullText = table.concat(effects, " ")
  local summary = {}

  -- Check for location/condition requirements
  local condition = ""
  if fullText:find("requires you to be in Annwyn") then
    condition = " (Annwyn)"
  elseif fullText:find("requires you to be in the Underworld") then
    condition = " (Underworld)"
  elseif fullText:find("requires you to be within an underground") then
    condition = " (Underground)"
  elseif fullText:find("requires you to be within a watery") then
    condition = " (Water)"
  elseif fullText:find("requires you to be within a forest") then
    condition = " (Forest)"
  elseif fullText:find("battlerage") and fullText:find("requires") then
    condition = " (Battlerage)"
  end

  -- Damage Reduction: "Reduces your physical damage taken by X%"
  local dmgType, dmgPct = fullText:match("[Rr]educes your (%w+) damage taken by (%d+)%%")
  if dmgType and dmgPct then
    table.insert(summary, "-" .. dmgPct .. "% " .. dmgType:sub(1,1):upper() .. dmgType:sub(2) .. " Dmg")
  end

  -- Resistance: "You gain X% resistance against Y"
  local resPct, resType = fullText:match("gain (%d+)%% resistance against (.-)%.")
  if resPct and resType then
    -- Shorten the resistance type
    resType = resType:gsub(" sourced damage", ""):gsub(" damage", ""):gsub("all ", "")
    resType = resType:gsub("physical", "Phys"):gsub("magical", "Magic"):gsub("asphyxiation", "Asphyx")
    table.insert(summary, "+" .. resPct .. "% vs " .. resType)
  end

  -- Celerity: "increases your celerity by X"
  local celVal = fullText:match("increases your celerity by (%d+)")
  if celVal then
    local celCondition = ""
    if fullText:find("stored battlerage") then celCondition = " w/BR" end
    table.insert(summary, "Celerity +" .. celVal .. celCondition)
  end

  -- Additional damage percent: "deal an additional X% damage"
  local addDmgPct = fullText:match("deal an additional (%d+)%% damage")
  if addDmgPct then
    table.insert(summary, "+" .. addDmgPct .. "% Dmg")
  end

  -- Additional damage type: "deal an additional blunt damage"
  local addDmgType = fullText:match("deal an additional (%w+) damage")
  if addDmgType and not addDmgPct then
    table.insert(summary, "+" .. addDmgType:sub(1,1):upper() .. addDmgType:sub(2) .. " Dmg")
  end

  -- Ignore resistance: "ignore X% of a denizen's Y resistance"
  local ignorePct, ignoreType = fullText:match("ignore (%d+)%% of a denizen's (.+) resistance")
  if ignorePct and ignoreType then
    ignoreType = ignoreType:gsub("physical ", "Phys "):gsub("magical ", "Magic ")
    table.insert(summary, "Ignore " .. ignorePct .. "% " .. ignoreType)
  end

  -- Blackout reduction: "Blackout from denizens will be X% shorter"
  local blackoutPct = fullText:match("[Bb]lackout.-will be (%d+)%% shorter")
  if blackoutPct then
    table.insert(summary, "-" .. blackoutPct .. "% Blackout")
  end

  -- Chance effect: "you have a X% chance"
  local chancePct, chanceEffect = fullText:match("you have a (%d+)%% chance to (.-)%.")
  if chancePct and chanceEffect then
    chanceEffect = chanceEffect:gsub("recover ", "Recover "):sub(1, 20)
    table.insert(summary, chancePct .. "% " .. chanceEffect)
  end

  -- Health regen: "health regeneration is increased" or "health will regenerate X% faster"
  local regenPct = fullText:match("health will regenerate (%d+)%% faster")
  if regenPct then
    local regenCond = ""
    if fullText:find("stored battlerage") then regenCond = " w/BR" end
    table.insert(summary, "+" .. regenPct .. "% HP Regen" .. regenCond)
  elseif fullText:find("health regeneration is increased") then
    regenPct = fullText:match("increased by (%d+)%%")
    if regenPct then
      table.insert(summary, "+" .. regenPct .. "% HP Regen")
    else
      table.insert(summary, "+HP Regen")
    end
  end

  -- Willpower regen: "your willpower will regenerate X% faster"
  local wpRegenPct = fullText:match("willpower will regenerate (%d+)%% faster")
  if wpRegenPct then
    local wpCond = ""
    if fullText:find("stored battlerage") then wpCond = " w/BR" end
    table.insert(summary, "+" .. wpRegenPct .. "% WP Regen" .. wpCond)
  end

  -- Health increased: "your health is increased by X%"
  local hpIncrease = fullText:match("health is increased by (%d+)%%")
  if hpIncrease then
    local hpCond = ""
    if fullText:find("suffused with battlerage") then hpCond = " w/BR" end
    table.insert(summary, "+" .. hpIncrease .. "% HP" .. hpCond)
  end

  -- Burst damage: "additional burst of X% Y damage" or "additional burst of X% Y Z damage"
  -- Try two-word type first (e.g., "physical cutting"), then single-word (e.g., "magical")
  local burstPct, burstType = fullText:match("additional burst of (%d+)%% (%w+ %w+) damage")
  if not burstPct then
    burstPct, burstType = fullText:match("additional burst of (%d+)%% (%w+) damage")
  end
  if burstPct and burstType then
    burstType = burstType:gsub("physical ", "Phys "):gsub("magical", "Magic"):gsub("physical", "Phys")
    local cdText = ""
    local cooldown = fullText:match("(%d+) second cooldown")
    if cooldown then cdText = " (" .. cooldown .. "s CD)" end
    table.insert(summary, "+" .. burstPct .. "% " .. burstType .. " Burst" .. cdText)
  end

  -- Endurance/willpower recovery
  local endWillPct = fullText:match("(%d+)%% chance to recover endurance")
  if endWillPct then
    table.insert(summary, endWillPct .. "% Endurance Recov")
  end
  local willPct = fullText:match("(%d+)%% chance to recover willpower")
  if willPct then
    table.insert(summary, willPct .. "% Willpower Recov")
  end

  -- Afflict chance: "X% chance to afflict them with Y"
  local afflictPct, afflictType = fullText:match("(%d+)%% chance to afflict them with (%w+)")
  if afflictPct and afflictType then
    table.insert(summary, afflictPct .. "% " .. afflictType)
  end

  -- If no patterns matched, return first 30 chars of first effect
  if #summary == 0 then
    return effects[1]:sub(1, 30) .. ".."
  end

  return table.concat(summary, ", ") .. condition
end

--------------------------------------------------------------------------------
-- BiS SCORING ENGINE - Extract numeric stats and score for PvE
--------------------------------------------------------------------------------

-- Extract structured numeric data from raw effects array
function gearAudit.scoreEffect(effects)
  if not effects or #effects == 0 then return {} end

  local fullText = table.concat(effects, " ")
  local scored = {}

  -- Detect condition
  if fullText:find("requires you to be in Annwyn") then
    scored.condition = "Annwyn"; scored.conditional = true
  elseif fullText:find("requires you to be in the Underworld") then
    scored.condition = "Underworld"; scored.conditional = true
  elseif fullText:find("requires you to be within an underground") then
    scored.condition = "Underground"; scored.conditional = true
  elseif fullText:find("requires you to be within a watery") then
    scored.condition = "Water"; scored.conditional = true
  elseif fullText:find("requires you to be within a forest") then
    scored.condition = "Forest"; scored.conditional = true
  end
  if fullText:find("battlerage") and fullText:find("requires") then
    scored.brCondition = true; scored.conditional = true
  end

  -- Additional damage %
  local addDmg = fullText:match("deal an additional (%d+)%% damage")
  if addDmg then scored.addDmgPct = tonumber(addDmg) end

  -- Celerity
  local cel = fullText:match("increases your celerity by (%d+)")
  if cel then scored.celerity = tonumber(cel) end

  -- Burst damage + cooldown
  local burstPct = fullText:match("additional burst of (%d+)%%")
  if burstPct then
    scored.burstPct = tonumber(burstPct)
    local cd = fullText:match("(%d+) second cooldown")
    scored.burstCooldown = cd and tonumber(cd) or 30  -- default 30s if not stated
  end

  -- Ignore denizen resistance
  local ignorePct = fullText:match("ignore (%d+)%% of a denizen")
  if ignorePct then scored.ignorePct = tonumber(ignorePct) end

  -- HP increase
  local hpPct = fullText:match("health is increased by (%d+)%%")
  if hpPct then scored.hpPct = tonumber(hpPct) end

  -- HP regen
  local hpRegen = fullText:match("health will regenerate (%d+)%% faster")
  if not hpRegen then
    hpRegen = fullText:match("health regeneration is increased by (%d+)%%")
  end
  if hpRegen then scored.hpRegenPct = tonumber(hpRegen) end

  -- WP regen
  local wpRegen = fullText:match("willpower will regenerate (%d+)%% faster")
  if wpRegen then scored.wpRegenPct = tonumber(wpRegen) end

  -- Damage reduction
  local dmgRedPct = fullText:match("[Rr]educes your %w+ damage taken by (%d+)%%")
  if dmgRedPct then scored.dmgReductionPct = tonumber(dmgRedPct) end

  -- Resistance
  local resPct = fullText:match("gain (%d+)%% resistance")
  if resPct then scored.resistPct = tonumber(resPct) end

  -- Blackout reduction
  local blackout = fullText:match("[Bb]lackout.-will be (%d+)%% shorter")
  if blackout then scored.blackoutPct = tonumber(blackout) end

  return scored
end

-- Calculate PvE score from scored effects
-- Returns: score (number), breakdown (table of {stat, value, weight, points})
function gearAudit.calculateScore(scored)
  local w = gearAudit.config.bisWeights
  local score = 0
  local breakdown = {}

  -- Determine conditional multiplier
  local mult = 1.0
  if scored.conditional then
    mult = scored.brCondition and w.brMult or w.conditionalMult
  end

  local function add(stat, value, weight)
    if not value or value == 0 then return end
    local pts = value * weight * mult
    score = score + pts
    table.insert(breakdown, {stat = stat, value = value, weight = weight, mult = mult, points = pts})
  end

  add("Additional Damage",    scored.addDmgPct,       w.addDmgPct)
  add("Celerity",             scored.celerity,         w.celerity)

  -- Burst: normalize to per-attack effective value (3s combat cycle)
  if scored.burstPct and scored.burstPct > 0 then
    local cd = scored.burstCooldown or 30
    local effective = scored.burstPct / (cd / 3)
    local pts = effective * w.burstEffective * mult
    score = score + pts
    table.insert(breakdown, {
      stat = "Burst Damage", value = scored.burstPct, weight = w.burstEffective,
      mult = mult, points = pts, note = string.format("%.1f%% eff (%ds CD)", effective, cd)
    })
  end

  add("Ignore Resistance",    scored.ignorePct,        w.ignorePct)
  add("HP Increase",          scored.hpPct,            w.hpPct)
  add("HP Regen",             scored.hpRegenPct,       w.hpRegenPct)
  add("Damage Reduction",     scored.dmgReductionPct,  w.dmgReductionPct)
  add("Resistance",           scored.resistPct,        w.resistPct)
  add("WP Regen",             scored.wpRegenPct,       w.wpRegenPct)
  add("Blackout Reduction",   scored.blackoutPct,      w.blackoutPct)

  return score, breakdown
end

-- Score a single gear item
function gearAudit.scoreItem(gearId)
  local gear = gearAudit.data[tonumber(gearId)]
  if not gear then return 0, {}, {} end
  local scored = gearAudit.scoreEffect(gear.effects)
  local score, breakdown = gearAudit.calculateScore(scored)
  return score, breakdown, scored
end

-- Group all items by slot, sorted by score desc within each slot
-- filterSet: optional set name to filter by
-- Returns: { [slot] = { {gear=..., score=..., breakdown=..., rank=...}, ... } }
function gearAudit.getBisBySlot(filterSet)
  local bySlot = {}

  for id, gear in pairs(gearAudit.data) do
    if gear.slot then
      local include = true
      if filterSet and gear.set then
        include = gear.set:lower():find(filterSet:lower())
      elseif filterSet and not gear.set then
        include = false
      end

      if include then
        local scored = gearAudit.scoreEffect(gear.effects)
        local score, breakdown = gearAudit.calculateScore(scored)
        bySlot[gear.slot] = bySlot[gear.slot] or {}
        table.insert(bySlot[gear.slot], {
          gear = gear, score = score, breakdown = breakdown, scored = scored
        })
      end
    end
  end

  -- Sort each slot by score descending, assign ranks
  for slot, items in pairs(bySlot) do
    table.sort(items, function(a, b) return a.score > b.score end)
    for i, item in ipairs(items) do
      item.rank = i
    end
  end

  return bySlot
end

-- Get scrap recommendations
function gearAudit.getScrapRecommendations(filterSet)
  local bySlot = gearAudit.getBisBySlot(filterSet)
  local scraps = {}

  for slot, items in pairs(bySlot) do
    if #items > 1 then
      -- Group by set within this slot
      local bySet = {}
      for _, item in ipairs(items) do
        local setName = item.gear.set or "Unknown"
        bySet[setName] = bySet[setName] or {}
        table.insert(bySet[setName], item)
      end

      -- Within each set, keep top N and scrap the rest
      local keepN = gearAudit.config.keepPerSet
      for setName, setItems in pairs(bySet) do
        if #setItems > keepN then
          local setBis = setItems[1].score  -- already sorted desc
          for i = keepN + 1, #setItems do
            local item = setItems[i]
            table.insert(scraps, {
              gear = item.gear, score = item.score, bisScore = setBis,
              slot = slot, set = setName, reason = "Rank #" .. i .. " (keeping top " .. keepN .. ")"
            })
          end
        end
      end
    end
  end

  -- Sort scraps by slot then score
  table.sort(scraps, function(a, b)
    if a.slot == b.slot then return a.score < b.score end
    return a.slot < b.slot
  end)

  return scraps
end

--------------------------------------------------------------------------------
-- BiS DISPLAY FUNCTIONS
--------------------------------------------------------------------------------

local function bisTag(rank, keepN)
  if rank == 1 then return "BiS" end
  if rank <= keepN then return "KEEP" end
  return "SCRAP"
end

local function bisTagColor(tag)
  if tag == "BiS" then return "<green>" end
  if tag == "SCRAP" then return "<red>" end
  return "<yellow>"
end

local function rarityShort(rarity)
  if rarity == "common" then return "cmn" end
  if rarity == "remnant" then return "rem" end
  return rarity or "?"
end

-- Sorted slot order for display
local SLOT_ORDER = {"head", "chest", "arms", "hands", "waist", "legs", "feet", "back", "neck", "ring", "trinket"}

local function sortedSlots(bySlot)
  local ordered = {}
  -- Add known slots in order
  for _, slot in ipairs(SLOT_ORDER) do
    if bySlot[slot] then table.insert(ordered, slot) end
  end
  -- Add any unknown slots at end
  for slot, _ in pairs(bySlot) do
    local found = false
    for _, s in ipairs(SLOT_ORDER) do
      if s == slot then found = true; break end
    end
    if not found then table.insert(ordered, slot) end
  end
  return ordered
end

-- Full BiS analysis display
function gearAudit.displayBis(slotFilter)
  local bySlot = gearAudit.getBisBySlot()
  local keepN = gearAudit.config.keepPerSet

  if gearAudit.tableSize(bySlot) == 0 then
    gearAudit.echo("No gear data. Run 'gearaudit' to collect or 'gearaudit load' to load saved data.")
    return
  end

  cecho("\n<cyan>================================================================================")
  cecho("\n<cyan>                       <white>PvE BiS ANALYSIS<cyan>")
  cecho("\n<cyan>================================================================================")

  local slots = sortedSlots(bySlot)
  for _, slot in ipairs(slots) do
    if not slotFilter or slot:lower() == slotFilter:lower() then
      local items = bySlot[slot]
      cecho(string.format("\n\n<white>  %s <DimGrey>(%d items)", slot:upper(), #items))

      -- Group by set
      local bySet = {}
      local setOrder = {}
      for _, item in ipairs(items) do
        local setName = item.gear.set or "Unknown"
        if not bySet[setName] then
          bySet[setName] = {}
          table.insert(setOrder, setName)
        end
        table.insert(bySet[setName], item)
      end

      -- Per-set BiS
      if #setOrder > 1 or (#setOrder == 1 and #bySet[setOrder[1]] > 1) then
        cecho("\n<DimGrey>  -- Per-Set BiS --")
        for _, setName in ipairs(setOrder) do
          local setItems = bySet[setName]
          cecho(string.format("\n<green>    %s<DimGrey>:", setName))
          for i, item in ipairs(setItems) do
            local tag = bisTag(i, keepN)
            local tagCol = bisTagColor(tag)
            local effectStr = gearAudit.summarizeEffect(item.gear.effects)
            if #effectStr > 35 then effectStr = effectStr:sub(1, 33) .. ".." end
            cecho(string.format(
              "\n<cyan>      #%-2d %s%-5s <yellow>%5.1f  <DimGrey>[%s] <white>%-6d <light_grey>%s",
              i, tagCol, tag, item.score, rarityShort(item.gear.rarity),
              item.gear.id or 0, effectStr
            ))
          end
        end
      end

      -- Overall BiS (top item across all sets)
      cecho("\n<DimGrey>  -- Overall BiS --")
      local top = items[1]
      if top then
        cecho(string.format(
          "\n<cyan>      #1  <green>BiS   <yellow>%5.1f  <DimGrey>[%s] <white>%-6d <green>%s",
          top.score, rarityShort(top.gear.rarity), top.gear.id or 0,
          top.gear.set or "Unknown"
        ))
      end
    end
  end

  cecho("\n\n<cyan>================================================================================")
  cecho("\n<grey>Use 'gearaudit score <id>' for detailed breakdown. 'gearaudit scrap' for scrap list.\n")
end

-- Single item score breakdown
function gearAudit.displayScore(gearId)
  local id = tonumber(gearId)
  if not id then
    gearAudit.echo("Invalid gear ID: " .. tostring(gearId))
    return
  end

  local gear = gearAudit.data[id]
  if not gear then
    gearAudit.echo("Gear ID " .. id .. " not found.")
    return
  end

  local score, breakdown, scored = gearAudit.scoreItem(id)

  cecho("\n<cyan>+------------------------------------------------------------------------------+")
  cecho(string.format("\n<cyan>| <white>SCORE BREAKDOWN - ID: %d", id))
  cecho("\n<cyan>+------------------------------------------------------------------------------+")
  cecho(string.format("\n<cyan>| <grey>Name:<cyan>    <white>%s", gear.name or "Unknown"))
  cecho(string.format("\n<cyan>| <grey>Set:<cyan>     <green>%s", gear.set or "None"))
  cecho(string.format("\n<cyan>| <grey>Slot:<cyan>    <yellow>%s", gear.slot or "Unknown"))
  cecho(string.format("\n<cyan>| <grey>Rarity:<cyan>  <magenta>%s  <grey>Months: <white>%s", gear.rarity or "?", tostring(gear.monthsLeft or "?")))

  if scored.conditional then
    local cond = scored.condition or (scored.brCondition and "Battlerage" or "Unknown")
    cecho(string.format("\n<cyan>| <grey>Condition:<cyan> <orange>%s <grey>(mult: %.1fx)", cond, scored.brCondition and gearAudit.config.bisWeights.brMult or gearAudit.config.bisWeights.conditionalMult))
  end

  cecho("\n<cyan>+------------------------------------------------------------------------------+")
  cecho("\n<cyan>| <white>Stat                     <grey>| <white>Value      <grey>| <white>Weight   <grey>| <white>Points")
  cecho("\n<cyan>+------------------------------------------------------------------------------+")

  if #breakdown == 0 then
    cecho("\n<cyan>|   <DimGrey>(No scorable stats found)")
  else
    for _, b in ipairs(breakdown) do
      local valStr = b.note or string.format("+%g", b.value)
      local multStr = ""
      if b.mult < 1.0 then multStr = string.format(" x%.1f", b.mult) end
      cecho(string.format(
        "\n<cyan>| <light_grey>%-24s <grey>| <white>%-10s <grey>| <white>x%-6.1f <grey>| <yellow>%5.1f%s",
        b.stat, valStr, b.weight, b.points, multStr
      ))
    end
  end

  cecho("\n<cyan>+------------------------------------------------------------------------------+")
  cecho(string.format("\n<cyan>| <white>TOTAL SCORE: <yellow>%.1f", score))
  cecho("\n<cyan>+------------------------------------------------------------------------------+")

  -- Show rank in slot
  if gear.slot then
    local bySlot = gearAudit.getBisBySlot()
    local slotItems = bySlot[gear.slot]
    if slotItems then
      for _, item in ipairs(slotItems) do
        if item.gear.id == id then
          cecho(string.format("\n<cyan>| <grey>Rank: <white>#%d of %d <grey>in <white>%s <grey>slot", item.rank, #slotItems, gear.slot:upper()))
          break
        end
      end
    end
  end

  cecho("\n<cyan>+------------------------------------------------------------------------------+\n")
end

-- Scrap recommendations display with copy-paste commands
function gearAudit.displayScrap(filterSet)
  local scraps = gearAudit.getScrapRecommendations(filterSet)

  if #scraps == 0 then
    gearAudit.echo("No scrap recommendations. All gear looks good!")
    return
  end

  cecho("\n<cyan>================================================================================")
  cecho("\n<cyan>                       <red>SCRAP RECOMMENDATIONS<cyan>")
  cecho("\n<cyan>================================================================================")

  for _, s in ipairs(scraps) do
    cecho(string.format(
      "\n<red>  #%-6d <white>(%s) <green>%s <grey>- score <yellow>%.1f <grey>(BiS: <yellow>%.1f<grey>)",
      s.gear.id or 0, s.slot, s.set, s.score, s.bisScore
    ))
    local effectStr = gearAudit.summarizeEffect(s.gear.effects)
    if #effectStr > 60 then effectStr = effectStr:sub(1, 58) .. ".." end
    cecho(string.format("\n<DimGrey>           %s <grey>- %s", s.gear.name or "Unknown", effectStr))
  end

  cecho("\n\n<cyan>--------------------------------------------------------------------------------")
  cecho(string.format("\n<white>  Queuing %d scrap commands (0.5s apart)...", #scraps))
  for i, s in ipairs(scraps) do
    local cmd = string.format("GEAR SCRAP %d CONFIRM", s.gear.id or 0)
    local delay = (i - 1) * 0.5
    tempTimer(delay, function()
      cecho(string.format("\n<yellow>    [%d/%d] %s", i, #scraps, cmd))
      send(cmd, false)
    end)
  end
  local totalTime = (#scraps - 1) * 0.5
  cecho(string.format("\n<grey>  ETA: %.0f seconds", totalTime))
  cecho("\n<cyan>================================================================================\n")
end

--------------------------------------------------------------------------------
-- LISTING PHASE - Parse GEAR LIST ALL output
--------------------------------------------------------------------------------

function gearAudit.setupListingTriggers()
  -- Trigger for gear list item lines
  -- Format: ID     Name                                     Rarity       Months left
  -- Example: 1667   a Moghedan helmet of recovery            common       68
  -- More flexible regex: uses \s+ instead of \s{2,} and no end anchor
  local t1 = tempRegexTrigger(
    [[^(\d+)\s+(.+?)\s+(common|rare|remnant)\s+(\d+)]],
    function()
      local id = tonumber(matches[2])
      local name = matches[3]:match("^%s*(.-)%s*$")  -- trim
      local rarity = matches[4]
      local monthsLeft = tonumber(matches[5])

      if id then
        gearAudit.data[id] = gearAudit.data[id] or {}
        gearAudit.data[id].id = id
        gearAudit.data[id].name = name
        gearAudit.data[id].rarity = rarity
        gearAudit.data[id].monthsLeft = monthsLeft

        table.insert(gearAudit.state.probeQueue, id)
      end
    end
  )
  table.insert(gearAudit.state.triggers, t1)

  -- Trigger for MORE prompt - auto-continue
  local t2 = tempTrigger(
    "[Type MORE if you wish to continue reading",
    function()
      if gearAudit.state.phase == "LISTING" then
        send("MORE", false)
      end
    end
  )
  table.insert(gearAudit.state.triggers, t2)

  -- Trigger for end of list - detect "You possess X/Y arcane ephemera" line
  local t3 = tempRegexTrigger(
    [[^You possess \d+/\d+ arcane ephemera]],
    function()
      if gearAudit.state.phase == "LISTING" and not gearAudit.state.listingComplete then
        gearAudit.state.listingComplete = true
        -- Small delay to ensure we captured everything
        local timer = tempTimer(0.5, function()
          gearAudit.transitionToProbing()
        end)
        table.insert(gearAudit.state.timers, timer)
      end
    end
  )
  table.insert(gearAudit.state.triggers, t3)
end

--------------------------------------------------------------------------------
-- PROBING PHASE - Send GEAR PROBE for each item
--------------------------------------------------------------------------------

function gearAudit.setupProbingTriggers()
  -- Trigger for Set line
  -- Format: Set:                     Fallen Adventurer's Gear (adventurer)
  local t1 = tempRegexTrigger(
    [[^Set:\s+(.+)$]],
    function()
      if gearAudit.state.currentProbeId then
        local id = gearAudit.state.currentProbeId
        local setLine = matches[2]:match("^%s*(.-)%s*$")
        -- Extract set name, removing the (code) part if present
        local setName = setLine:match("^(.-)%s*%([%w_]+%)$") or setLine
        gearAudit.data[id].set = setName:match("^%s*(.-)%s*$")
      end
    end
  )
  table.insert(gearAudit.state.triggers, t1)

  -- Trigger for Slot line
  -- Format: Slot:                    chest
  local t2 = tempRegexTrigger(
    [[^Slot:\s+(\w+)$]],
    function()
      if gearAudit.state.currentProbeId then
        local id = gearAudit.state.currentProbeId
        gearAudit.data[id].slot = matches[2]
      end
    end
  )
  table.insert(gearAudit.state.triggers, t2)

  -- Trigger for Effects: line - start capturing
  local t3 = tempTrigger(
    "Effects:",
    function()
      if gearAudit.state.currentProbeId then
        gearAudit.state.capturingEffects = true
        gearAudit.state.currentEffects = {}
        gearAudit.state.effectDashCount = 0
      end
    end
  )
  table.insert(gearAudit.state.triggers, t3)

  -- Trigger for dashed lines in effects section
  -- First dash (after Effects:) = start capturing, Second dash = end capturing
  local t4 = tempRegexTrigger(
    [[^-{10,}$]],
    function()
      if gearAudit.state.capturingEffects and gearAudit.state.currentProbeId then
        gearAudit.state.effectDashCount = gearAudit.state.effectDashCount + 1

        if gearAudit.state.effectDashCount >= 2 then
          -- Second dashed line - end of effects, save and move to next probe
          local id = gearAudit.state.currentProbeId
          if #gearAudit.state.currentEffects > 0 then
            gearAudit.data[id].effects = gearAudit.state.currentEffects
          end
          gearAudit.state.capturingEffects = false
          gearAudit.state.currentEffects = {}
          gearAudit.state.effectDashCount = 0

          -- Schedule next probe
          local timer = tempTimer(gearAudit.config.probeDelay, function()
            gearAudit.probeNext()
          end)
          table.insert(gearAudit.state.timers, timer)
        end
        -- First dashed line (effectDashCount == 1) - just skip it, content comes next
      end
    end
  )
  table.insert(gearAudit.state.triggers, t4)

  -- Trigger for effect content lines (between the two dashed lines)
  local t5 = tempRegexTrigger(
    [[^(.+)$]],
    function()
      -- Only capture if we're between the two dashed lines (effectDashCount == 1)
      if gearAudit.state.capturingEffects and gearAudit.state.currentProbeId and gearAudit.state.effectDashCount == 1 then
        local line = matches[2]
        local trimmed = line:match("^%s*(.-)%s*$")
        -- Skip empty lines and dashed lines (handled by t4)
        if trimmed ~= "" and not trimmed:match("^%-+$") then
          table.insert(gearAudit.state.currentEffects, trimmed)
        end
      end
    end
  )
  table.insert(gearAudit.state.triggers, t5)
end

function gearAudit.transitionToProbing()
  gearAudit.cleanup()  -- Clean up listing triggers

  local count = #gearAudit.state.probeQueue
  gearAudit.echo("Found " .. count .. " gear items. Starting probes...")

  if count == 0 then
    gearAudit.complete()
    return
  end

  gearAudit.state.phase = "PROBING"
  gearAudit.state.currentProbeIndex = 0
  gearAudit.setupProbingTriggers()
  gearAudit.probeNext()
end

function gearAudit.probeNext()
  gearAudit.state.currentProbeIndex = gearAudit.state.currentProbeIndex + 1
  local index = gearAudit.state.currentProbeIndex
  local queue = gearAudit.state.probeQueue

  if index > #queue then
    gearAudit.complete()
    return
  end

  local id = queue[index]
  gearAudit.state.currentProbeId = id
  gearAudit.state.capturingEffects = false
  gearAudit.state.currentEffects = {}
  gearAudit.state.effectDashCount = 0

  -- Progress indicator every 10 items or at the end
  if index % 10 == 0 or index == #queue then
    gearAudit.echo("Probing... " .. index .. "/" .. #queue)
  end

  send("GEAR PROBE " .. id, false)
end

--------------------------------------------------------------------------------
-- COMPLETION
--------------------------------------------------------------------------------

function gearAudit.complete()
  gearAudit.cleanup()
  gearAudit.state.phase = "COMPLETE"

  local count = gearAudit.tableSize(gearAudit.data)

  gearAudit.echo("Audit complete! Collected data for " .. count .. " gear items.")
  gearAudit.save()

  gearAudit.state.phase = "IDLE"
  gearAudit.display()
end

--------------------------------------------------------------------------------
-- MAIN COMMAND FUNCTIONS
--------------------------------------------------------------------------------

function gearAudit.start()
  if gearAudit.state.phase ~= "IDLE" then
    gearAudit.echo("Audit already in progress. Use 'gearaudit stop' to cancel.")
    return
  end

  gearAudit.init()
  gearAudit.data = {}  -- Clear previous data
  gearAudit.echo("Starting gear audit. Sending GEAR LIST ALL...")

  gearAudit.state.phase = "LISTING"
  gearAudit.setupListingTriggers()

  -- Set timeout
  local timer = tempTimer(gearAudit.config.timeout, function()
    if gearAudit.state.phase ~= "IDLE" then
      gearAudit.echo("<red>Audit timed out after " .. gearAudit.config.timeout .. " seconds. Saving partial data...")
      gearAudit.save()
      gearAudit.cleanup()
      gearAudit.state.phase = "IDLE"
    end
  end)
  table.insert(gearAudit.state.timers, timer)

  send("GEAR LIST ALL")
end

function gearAudit.stop()
  if gearAudit.state.phase == "IDLE" then
    gearAudit.echo("No audit in progress.")
    return
  end
  gearAudit.cleanup()
  gearAudit.state.phase = "IDLE"
  gearAudit.echo("Gear audit cancelled. Collected " .. gearAudit.tableSize(gearAudit.data) .. " items before stopping.")
  if gearAudit.tableSize(gearAudit.data) > 0 then
    gearAudit.save()
  end
end

--------------------------------------------------------------------------------
-- DISPLAY FUNCTIONS
--------------------------------------------------------------------------------

function gearAudit.display(filter)
  filter = filter or {}

  local items = {}
  for id, gear in pairs(gearAudit.data) do
    local include = true

    if filter.set and gear.set then
      include = include and gear.set:lower():find(filter.set:lower())
    elseif filter.set and not gear.set then
      include = false
    end

    if filter.slot then
      include = include and gear.slot and gear.slot:lower() == filter.slot:lower()
    end

    if filter.effect then
      local hasEffect = false
      for _, eff in ipairs(gear.effects or {}) do
        if eff:lower():find(filter.effect:lower()) then
          hasEffect = true
          break
        end
      end
      include = include and hasEffect
    end

    if include then
      table.insert(items, gear)
    end
  end

  -- Sort by set, then slot
  table.sort(items, function(a, b)
    if (a.set or "") == (b.set or "") then
      return (a.slot or "") < (b.slot or "")
    end
    return (a.set or "") < (b.set or "")
  end)

  if #items == 0 then
    gearAudit.echo("No gear items to display. Run 'gearaudit' to collect data or 'gearaudit load' to load saved data.")
    return
  end

  -- Display header
  cecho("\n<cyan>+--------+------------------------------+----------+----------------------------------------+")
  cecho("\n<cyan>| <white>ID<cyan>     | <white>Set<cyan>                          | <white>Slot<cyan>     | <white>Effects<cyan>                                |")
  cecho("\n<cyan>+--------+------------------------------+----------+----------------------------------------+")

  for _, gear in ipairs(items) do
    local effectStr = gearAudit.summarizeEffect(gear.effects)
    if #effectStr > 40 then
      effectStr = effectStr:sub(1, 38) .. ".."
    end

    cecho(string.format(
      "\n<cyan>| <yellow>%-6d<cyan> | <green>%-28s<cyan> | <white>%-8s<cyan> | <light_grey>%-40s<cyan>|",
      gear.id or 0,
      (gear.set or "Unknown"):sub(1, 28),
      (gear.slot or "?"):sub(1, 8),
      effectStr
    ))
  end

  cecho("\n<cyan>+--------+------------------------------+----------+----------------------------------------+")
  cecho("\n<grey>Total: " .. #items .. " items\n")
end

function gearAudit.showBySet(setName)
  gearAudit.display({set = setName})
end

function gearAudit.showBySlot(slotName)
  gearAudit.display({slot = slotName})
end

function gearAudit.showByEffect(keyword)
  gearAudit.display({effect = keyword})
end

-- Show detailed info for a specific gear ID
function gearAudit.showDetail(gearId)
  local id = tonumber(gearId)
  if not id then
    gearAudit.echo("Invalid gear ID: " .. tostring(gearId))
    return
  end

  local gear = gearAudit.data[id]
  if not gear then
    gearAudit.echo("Gear ID " .. id .. " not found in audit data.")
    return
  end

  cecho("\n<cyan>+------------------------------------------------------------------------------+")
  cecho("\n<cyan>| <white>GEAR DETAILS - ID: " .. id .. "<cyan>")
  cecho("\n<cyan>+------------------------------------------------------------------------------+")
  cecho("\n<cyan>| <grey>Name:<cyan>    <white>" .. (gear.name or "Unknown"))
  cecho("\n<cyan>| <grey>Set:<cyan>     <green>" .. (gear.set or "None"))
  cecho("\n<cyan>| <grey>Slot:<cyan>    <yellow>" .. (gear.slot or "Unknown"))
  cecho("\n<cyan>| <grey>Rarity:<cyan>  <magenta>" .. (gear.rarity or "Unknown"))
  cecho("\n<cyan>| <grey>Decay:<cyan>   <white>" .. (gear.monthsLeft or "?") .. " months")
  cecho("\n<cyan>| <grey>Summary:<cyan>  <white>" .. gearAudit.summarizeEffect(gear.effects))
  cecho("\n<cyan>| <grey>Effects:<cyan>")
  if gear.effects and #gear.effects > 0 then
    for _, eff in ipairs(gear.effects) do
      cecho("\n<cyan>|   <light_grey>" .. eff)
    end
  else
    cecho("\n<cyan>|   <DimGrey>(No effects recorded)")
  end
  cecho("\n<cyan>+------------------------------------------------------------------------------+\n")
end

--------------------------------------------------------------------------------
-- HELP
--------------------------------------------------------------------------------

function gearAudit.help()
  cecho("\n<cyan>+----------------------------------------------------------------------+")
  cecho("\n<cyan>|                    <white>GEAR AUDIT COMMANDS<cyan>                             |")
  cecho("\n<cyan>+----------------------------------------------------------------------+")
  cecho("\n<cyan>| <green>gearaudit<cyan>              - Start a new gear audit                    |")
  cecho("\n<cyan>| <green>gearaudit stop<cyan>         - Cancel current audit                      |")
  cecho("\n<cyan>| <green>gearaudit show<cyan>         - Display all collected gear                |")
  cecho("\n<cyan>| <green>gearaudit detail <id><cyan>  - Show full details for a gear ID           |")
  cecho("\n<cyan>| <green>gearaudit set <name><cyan>   - Filter by set name                        |")
  cecho("\n<cyan>| <green>gearaudit slot <slot><cyan>  - Filter by slot (head, chest, hands, etc)  |")
  cecho("\n<cyan>| <green>gearaudit effect <kw><cyan>  - Search effects by keyword                 |")
  cecho("\n<cyan>| <green>gearaudit save<cyan>         - Save data to file                         |")
  cecho("\n<cyan>| <green>gearaudit load<cyan>         - Load saved data                           |")
  cecho("\n<cyan>| <green>gearaudit status<cyan>       - Show current audit status                 |")
  cecho("\n<cyan>| <green>gearaudit clear<cyan>        - Clear all collected data                  |")
  cecho("\n<cyan>| <green>gearaudit help<cyan>         - Show this help                            |")
  cecho("\n<cyan>+----------------------------------------------------------------------+")
  cecho("\n<cyan>|                    <white>PvE BiS ANALYSIS<cyan>                                |")
  cecho("\n<cyan>+----------------------------------------------------------------------+")
  cecho("\n<cyan>| <green>gearaudit bis<cyan>          - PvE Best in Slot analysis (all slots)     |")
  cecho("\n<cyan>| <green>gearaudit bis <slot><cyan>   - BiS analysis for a specific slot          |")
  cecho("\n<cyan>| <green>gearaudit score <id><cyan>   - Detailed score breakdown for a gear ID    |")
  cecho("\n<cyan>| <green>gearaudit scrap<cyan>        - Scrap recommendations + commands          |")
  cecho("\n<cyan>| <green>gearaudit scrap <set><cyan>  - Scrap recommendations for a set           |")
  cecho("\n<cyan>+----------------------------------------------------------------------+\n")
end

--------------------------------------------------------------------------------
-- COMMAND HANDLER
--------------------------------------------------------------------------------

function gearAudit.command(args)
  args = args or ""
  local cmd, rest = args:match("^(%S+)%s*(.*)$")
  cmd = (cmd or ""):lower()

  if cmd == "" or cmd == "start" then
    gearAudit.start()
  elseif cmd == "stop" or cmd == "cancel" then
    gearAudit.stop()
  elseif cmd == "show" or cmd == "display" or cmd == "list" then
    gearAudit.display()
  elseif cmd == "detail" or cmd == "info" then
    if rest and rest ~= "" then
      gearAudit.showDetail(rest)
    else
      gearAudit.echo("Usage: gearaudit detail <gear_id>")
    end
  elseif cmd == "set" then
    if rest and rest ~= "" then
      gearAudit.showBySet(rest)
    else
      gearAudit.echo("Usage: gearaudit set <set_name>")
    end
  elseif cmd == "slot" then
    if rest and rest ~= "" then
      gearAudit.showBySlot(rest)
    else
      gearAudit.echo("Usage: gearaudit slot <slot_name>")
    end
  elseif cmd == "effect" or cmd == "effects" then
    if rest and rest ~= "" then
      gearAudit.showByEffect(rest)
    else
      gearAudit.echo("Usage: gearaudit effect <keyword>")
    end
  elseif cmd == "save" then
    gearAudit.save()
  elseif cmd == "load" then
    gearAudit.load()
  elseif cmd == "status" then
    gearAudit.status()
  elseif cmd == "bis" then
    gearAudit.displayBis(rest ~= "" and rest or nil)
  elseif cmd == "score" then
    if rest and rest ~= "" then
      gearAudit.displayScore(rest)
    else
      gearAudit.echo("Usage: gearaudit score <gear_id>")
    end
  elseif cmd == "scrap" then
    gearAudit.displayScrap(rest ~= "" and rest or nil)
  elseif cmd == "clear" then
    gearAudit.data = {}
    gearAudit.echo("Cleared all gear audit data.")
  elseif cmd == "help" or cmd == "?" then
    gearAudit.help()
  else
    gearAudit.echo("Unknown command: " .. cmd)
    gearAudit.help()
  end
end

--------------------------------------------------------------------------------
-- EVENT HANDLERS
--------------------------------------------------------------------------------

-- Save on disconnect
registerAnonymousEventHandler("sysDisconnectionEvent", function()
  if gearAudit.state.phase ~= "IDLE" then
    gearAudit.echo("Disconnected - saving partial audit data...")
    gearAudit.save()
    gearAudit.cleanup()
    gearAudit.state.phase = "IDLE"
  end
end)

-- Optional: Load on system init
registerAnonymousEventHandler("ataxia system loaded", function()
  -- Auto-load saved data if it exists
  local separator = package.config:sub(1, 1)
  local filepath = getMudletHomeDir() .. separator .. gearAudit.config.saveFile
  if io.exists(filepath) then
    gearAudit.load()
  end
end)

--------------------------------------------------------------------------------
-- ALIAS SETUP NOTE
--------------------------------------------------------------------------------
-- To use this system, create a Mudlet alias:
--   Pattern: ^gearaudit\s*(.*)$
--   Script:  gearAudit.command(matches[2])
--
-- Or manually call: gearAudit.command("start"), gearAudit.command("show"), etc.
--------------------------------------------------------------------------------
