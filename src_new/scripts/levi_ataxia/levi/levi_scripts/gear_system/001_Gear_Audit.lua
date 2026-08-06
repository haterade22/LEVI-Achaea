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
    bonusDmgPct     = 10.0,  -- "attacks deal X% bonus damage" - same thing as addDmgPct
    celerity         = 8.0,  -- attack speed
    burstEffective   = 7.0,  -- burst dmg normalized to per-attack value
    ignorePct        = 6.0,  -- ignore denizen resistance
    critChancePct    = 5.0,  -- more crits = more damage, below flat damage%
    critDmgPct       = 4.0,  -- only pays on the crit fraction
    hpPct            = 3.0,  -- HP increase
    brDmgPct         = 3.0,  -- battlerage-only damage, a fraction of rounds
    hpRegenPct       = 2.5,  -- HP regen
    dmgReductionPct  = 2.0,  -- damage reduction
    rageGenPct       = 2.0,  -- enables battlerage, deals no damage itself
    brRageGenPct     = 2.0,  -- rage from battlerage abilities
    bleedDmgPct      = 2.0,  -- conditional on sustaining bleed
    -- BATTLERAGE COOLDOWN (v4.7.226). Was scored at ZERO -- no pattern for it existed
    -- anywhere in this file, so every "your battlerage abilities will cool down X% faster"
    -- piece ranked below a +1% crit trinket and fell straight into the scrap list. Rated just
    -- above rage generation: rage only ENABLES a battlerage, whereas the cooldown gates how
    -- often one can be used at all, and the Semiro log shows both binding in the same fight
    -- ("You must wait a short time before you can use a battlerage ability again." alongside
    -- "you lack the necessary Rage").
    brCooldownPct    = 2.5,
    -- Crit-on-strike DoT: also previously unscored. A fraction of crit damage, which is
    -- itself a fraction of hits, so it sits below flat crit damage.
    critDotPct       = 1.5,
    -- Mana regen was the last unscored family in the Mnemosyne set (~11 head pieces at zero).
    -- Below HP regen because HP is what actually binds when bashing -- but not dismissed:
    -- running out of mana IS a kill condition for some classes (Psion excise, the Kai Choke
    -- 250-mana floor), so a head that only offers mana is still worth more than nothing.
    manaRegenPct     = 1.5,
    resistPct        = 1.5,  -- resistance
    wpRegenPct       = 1.0,  -- WP regen
    blackoutPct      = 1.0,  -- blackout reduction
    conditionalMult  = 0.5,  -- location-locked gear discounted 50%
    brMult           = 0.7,  -- battlerage-conditional discounted 30%
  },
  -- Table rendering. Columns auto-size to content; the Effects column takes whatever
  -- width is left and wraps rather than truncating.
  display = {
    width      = nil,   -- nil = auto-detect console columns; set a number to pin it
    maxWidth   = 200,   -- clamp for very wide consoles
    fallback   = 120,   -- used when getColumnCount() is unavailable
    minEffects = 40,    -- Effects column never narrower than this
  },
  keepPerSet = 3,             -- Keep top N items per slot per set, scrap the rest
  slotRules = {
    hands = {
      minBurstPct = 15,       -- Scrap burst items under 15%
      maxBurstKeep = 3,       -- Keep at most 3 burst items (sorted by burst% desc)
      minDmgPct = 2,          -- Scrap damage items under 2%
    },
  },
}

--------------------------------------------------------------------------------
-- UTILITY FUNCTIONS
--------------------------------------------------------------------------------

function gearAudit.echo(text)
  cecho("\n<dark_orchid>[<light_slate_blue>GearAudit<dark_orchid>]<lavender>: <plum>" .. text)
end

--------------------------------------------------------------------------------
-- TABLE RENDERING HELPERS
--------------------------------------------------------------------------------

-- Usable console width in characters. getColumnCount() is not present in every
-- Mudlet build (and not in the test mock), so it is pcall-guarded.
function gearAudit.consoleWidth()
  local d = gearAudit.config.display
  if d.width then return d.width end

  local ok, cols = pcall(getColumnCount)
  if ok and type(cols) == "number" and cols > 40 then
    return math.min(cols - 2, d.maxWidth)
  end
  return d.fallback
end

-- Wrap text to `width` columns on word boundaries. Words longer than the column are
-- hard-split rather than overflowing the border. Always returns at least one line.
function gearAudit.wrapText(text, width)
  text = tostring(text or "")
  width = math.max(1, tonumber(width) or 1)

  local lines = {}
  local line = ""

  local function flush()
    table.insert(lines, line)
    line = ""
  end

  for word in text:gmatch("%S+") do
    -- Hard-split anything that can never fit on a line of its own
    while #word > width do
      if line ~= "" then flush() end
      table.insert(lines, word:sub(1, width))
      word = word:sub(width + 1)
    end

    if line == "" then
      line = word
    elseif #line + 1 + #word <= width then
      line = line .. " " .. word
    else
      flush()
      line = word
    end
  end

  if line ~= "" or #lines == 0 then flush() end
  return lines
end

-- "+------+-----+" rule matching a widths array (one cell = width + 2 padding spaces)
function gearAudit.tableRule(widths)
  local parts = {}
  for _, w in ipairs(widths) do
    table.insert(parts, string.rep("-", w + 2))
  end
  return "+" .. table.concat(parts, "+") .. "+"
end

-- "| a | b |" row. `colors` is an optional parallel array of colour names; cells are
-- left-aligned and padded to their column width.
function gearAudit.tableRow(widths, cells, colors)
  local out = "<cyan>|"
  for i, w in ipairs(widths) do
    local cell = tostring(cells[i] or "")
    local color = (colors and colors[i]) or "light_grey"
    out = out .. " <" .. color .. ">" .. cell .. string.rep(" ", w - #cell) .. " <cyan>|"
  end
  return out
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
  -- Kill scrap event handler if active
  if gearAudit.scrapEventHandler then
    killAnonymousEventHandler(gearAudit.scrapEventHandler)
    gearAudit.scrapEventHandler = nil
  end
  if gearAudit.scrapTimeoutTimer then
    killTimer(gearAudit.scrapTimeoutTimer)
    gearAudit.scrapTimeoutTimer = nil
  end
  gearAudit.scrapQueue = nil
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
  -- Non-greedy: effects are concatenated, so (.+) would swallow every following sentence.
  local ignorePct, ignoreType = fullText:match("ignore (%d+)%% of a denizen's (.-) resistance")
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
    chanceEffect = chanceEffect:gsub("recover ", "Recover ")
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

  -- Bonus damage: "Your attacks will deal X% bonus damage ..."
  local bonusDmg = fullText:match("attacks will deal (%d+)%% bonus")
  if bonusDmg then
    table.insert(summary, "+" .. bonusDmg .. "% Bonus Dmg")
  end

  -- Rage generation. The "less" form must be tested FIRST or the generic
  -- "generate (%d+)%%" below would label a penalty as a bonus.
  local rageLess = fullText:match("generate (%d+)%% less")
  if rageLess then
    table.insert(summary, "-" .. rageLess .. "% Rage Gen")
  else
    local rageGen = fullText:match("attacks will generate (%d+)%%")
    if rageGen then
      table.insert(summary, "+" .. rageGen .. "% Rage Gen")
    end
  end

  -- Battlerage ability modifiers
  local brDmg = fullText:match("battlerage abilities will deal (%d+)%%")
  if brDmg then
    table.insert(summary, "+" .. brDmg .. "% BR Dmg")
  end
  local brRage = fullText:match("battlerage abilities will generate (%d+)%%")
  if brRage then
    table.insert(summary, "+" .. brRage .. "% BR Rage")
  end

  -- Critical hits
  local critDmg = fullText:match("[Ii]ncreases the damage of your critical.-(%d+)%%")
  if critDmg then
    table.insert(summary, "+" .. critDmg .. "% Crit Dmg")
  end
  local critChance = fullText:match("[Ii]ncreases your chance to deal.-(%d+)%%")
  if critChance then
    table.insert(summary, "+" .. critChance .. "% Crit Chance")
  end
  -- The captured clause continues the game's own sentence, so the percent stays in
  -- front of it: "Crit: 16% of the damage dealt is returned ..."
  -- COMPACT, not a sentence fragment (v4.7.226). These three used to splice the game's own
  -- clause onto a label, producing "Bleed: a denizen, you will automatically clot 18% of it" --
  -- ungrammatical, and long enough to force every such row to wrap onto two lines in the audit
  -- table. The column exists to be SCANNED; the full text is a `gearaudit detail <id>` away.
  -- The on-crit clause is NOT always a DoT -- lifesteal ("returned as health") uses the same
  -- opener, and an existing test proves it. So the effect is TAGGED from its own wording
  -- rather than assumed; anything unrecognised keeps a clipped version of the real clause,
  -- which is still shorter than the whole sentence but never claims something false.
  local onCritPct, onCritClause = fullText:match("[Ww]hen you critically strike, (%d+)%%%s*(.-)%.")
  if onCritPct then
    local tag
    if not onCritClause or onCritClause == "" then
      tag = nil
    elseif onCritClause:find("DoT") or onCritClause:find("over the next") then
      tag = "as DoT"
    elseif onCritClause:find("returned as health") then
      tag = "as health"
    elseif #onCritClause > 22 then
      tag = onCritClause:sub(1, 21) .. "."
    else
      tag = onCritClause
    end
    table.insert(summary, "Crit: " .. onCritPct .. "%" .. (tag and (" " .. tag) or ""))
  end
  local brCdPct = fullText:match("battlerage abilities will cool down (%d+)%%")
  if brCdPct then
    -- Was not summarised AT ALL, so the whole two-sentence effect printed verbatim -- the
    -- single biggest cause of wrapping in the table, across ~20 chest pieces.
    local where = fullText:find("within the waters of the Mnemosyne") and " (Mnem)" or ""
    table.insert(summary, "BR cooldown -" .. brCdPct .. "%" .. where)
  end

  -- Stored-battlerage clause: "While you have any amount of stored battlerage, X."
  local storedBR = fullText:match("[Ww]hile you have any amount of stored battlerage,%s*(.-)%.")
  if storedBR then
    table.insert(summary, "w/BR: " .. storedBR)
  end

  -- Bleed synergy: "When sustaining bleeding from X, ..."
  local clotPct = fullText:match("[Ww]hen sustaining bleeding from.-automatically clot (%d+)%%")
  if clotPct then
    table.insert(summary, "Auto-clot " .. clotPct .. "%")
  else
    local bleed = fullText:match("[Ww]hen sustaining bleeding from%s*(.-)%.")
    if bleed then table.insert(summary, "Bleed: " .. bleed) end
  end

  -- Experience loss reduction
  local xpLoss = fullText:match("lose (%d+)%% less experience")
  if xpLoss then
    table.insert(summary, "-" .. xpLoss .. "% XP Loss")
  end

  -- "Provides a X% chance to Y."
  local providesPct, providesEffect = fullText:match("[Pp]rovides a (%d+)%% chance to (.-)%.")
  if providesPct and providesEffect then
    table.insert(summary, providesPct .. "% " .. providesEffect)
  end

  -- Execute-style: "When striking a denizen below X, ..."
  local execPct = fullText:match("[Ww]hen striking a denizen below.-(%d+)%% bonus")
  if execPct then
    table.insert(summary, "Execute +" .. execPct .. "%")
  else
    local execute = fullText:match("[Ww]hen striking a denizen below%s*(.-)%.")
    if execute then table.insert(summary, "Execute: " .. execute) end
  end

  -- Respawn modifier: "Denizens you slay will respawn X."
  local respawn = fullText:match("[Dd]enizens you slay will respawn%s*(.-)%.")
  if respawn then
    table.insert(summary, "Respawn: " .. respawn)
  end

  -- No pattern matched: show the raw effect text IN FULL. The display wraps rather
  -- than truncates, so an unrecognised effect stays readable (and its wording is what
  -- a new pattern gets written from).
  if #summary == 0 then
    return table.concat(effects, " ")
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
  elseif fullText:find("within the waters of the Mnemosyne") then
    -- NAMED but NOT discounted (v4.7.226). Every other condition here is a place we pass
    -- through; the Mnemosyne is where this character does essentially all of their bashing, so
    -- applying `conditionalMult` would under-rate the gear precisely where it is worn. It is
    -- still recorded, so `gearaudit score` shows the restriction and anyone bashing elsewhere
    -- can see at a glance why the piece is dead weight for them.
    scored.condition = "Mnemosyne"
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
  local manaRegen = fullText:match("mana will regenerate (%d+)%% faster")
  if manaRegen then scored.manaRegenPct = tonumber(manaRegen) end
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

  -- Bonus damage ("attacks will deal X% bonus damage")
  local bonusDmg = fullText:match("attacks will deal (%d+)%% bonus")
  if bonusDmg then scored.bonusDmgPct = tonumber(bonusDmg) end

  -- Rage generation. "less" first, or the penalty scores as a bonus.
  local rageLess = fullText:match("generate (%d+)%% less")
  if rageLess then
    scored.rageGenPct = -tonumber(rageLess)
  else
    local rageGen = fullText:match("attacks will generate (%d+)%%")
    if rageGen then scored.rageGenPct = tonumber(rageGen) end
  end

  -- Battlerage ability modifiers
  local brDmg = fullText:match("battlerage abilities will deal (%d+)%%")
  if brDmg then scored.brDmgPct = tonumber(brDmg) end
  local brRage = fullText:match("battlerage abilities will generate (%d+)%%")
  if brRage then scored.brRageGenPct = tonumber(brRage) end
  -- "Your battlerage abilities will cool down 21% faster." Previously unscored ENTIRELY --
  -- no pattern for it existed anywhere in this file.
  local brCd = fullText:match("battlerage abilities will cool down (%d+)%%")
  if brCd then scored.brCooldownPct = tonumber(brCd) end
  -- "When you critically strike, 17% of the damage will be dealt as an additional DoT..."
  -- The summariser recognised this shape; the scorer had no stat for it.
  local critDot = fullText:match("[Ww]hen you critically strike, (%d+)%%")
  if critDot then scored.critDotPct = tonumber(critDot) end

  -- Critical hits
  local critDmg = fullText:match("[Ii]ncreases the damage of your critical.-(%d+)%%")
  if critDmg then scored.critDmgPct = tonumber(critDmg) end
  local critChance = fullText:match("[Ii]ncreases your chance to deal.-(%d+)%%")
  if critChance then scored.critChancePct = tonumber(critChance) end

  -- Bleed synergy, only when it carries a number
  local bleedPct = fullText:match("[Ww]hen sustaining bleeding from.-(%d+)%%")
  if bleedPct then scored.bleedDmgPct = tonumber(bleedPct) end

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
  add("Bonus Damage",         scored.bonusDmgPct,      w.bonusDmgPct)
  add("Crit Chance",          scored.critChancePct,    w.critChancePct)
  add("Crit Damage",          scored.critDmgPct,       w.critDmgPct)
  add("HP Increase",          scored.hpPct,            w.hpPct)
  add("Battlerage Damage",    scored.brDmgPct,         w.brDmgPct)
  add("HP Regen",             scored.hpRegenPct,       w.hpRegenPct)
  add("Damage Reduction",     scored.dmgReductionPct,  w.dmgReductionPct)
  add("Rage Generation",      scored.rageGenPct,       w.rageGenPct)
  add("Battlerage Rage Gen",  scored.brRageGenPct,     w.brRageGenPct)
  add("Battlerage Cooldown",  scored.brCooldownPct,    w.brCooldownPct)
  add("Crit DoT",             scored.critDotPct,       w.critDotPct)
  add("Bleed Damage",         scored.bleedDmgPct,      w.bleedDmgPct)
  add("Resistance",           scored.resistPct,        w.resistPct)
  add("WP Regen",             scored.wpRegenPct,       w.wpRegenPct)
  add("Mana Regen",           scored.manaRegenPct,     w.manaRegenPct)
  add("Blackout Reduction",   scored.blackoutPct,      w.blackoutPct)

  return score, breakdown
end

-- ---------------------------------------------------------------------------
-- BEST IN SLOT *PER CATEGORY* (v4.7.226)
-- ---------------------------------------------------------------------------
-- User: "We must categorize them.. Best in Slot per category. Best damage, rage generation,
-- defensive stuff, etc per slot."
--
-- Exactly right, and the single-score BiS was hiding the real decision. One chest slot holds
-- three genuinely different pieces -- +23% bonus damage, +16% rage generation, -21% battlerage
-- cooldown -- and collapsing them into one number does not tell you which to wear, it tells
-- you which the WEIGHTS happen to prefer. The weights are a guess; the category split is a
-- fact about the gear.
--
-- Each stat belongs to exactly one category, so a category score is a strict subset of the
-- total and the two can never disagree about what an item does.
gearAudit.CATEGORIES = {
  { key = "damage",  label = "Damage",     colour = "indian_red",
    stats = { "addDmgPct", "bonusDmgPct", "burst", "ignorePct", "critChancePct",
              "critDmgPct", "critDotPct", "celerity", "execute" } },
  { key = "rage",    label = "Rage / BR",  colour = "gold",
    stats = { "rageGenPct", "brRageGenPct", "brCooldownPct", "brDmgPct" } },
  { key = "defence", label = "Defensive",  colour = "cyan",
    stats = { "hpPct", "hpRegenPct", "dmgReductionPct", "resistPct", "bleedDmgPct",
              "wpRegenPct", "manaRegenPct", "blackoutPct" } },
}

-- Which category owns a stat, or nil for one deliberately left out of the split (XP loss,
-- respawn speed -- real effects, but not things you would ever build a slot around).
function gearAudit.statCategory(stat)
  for _, cat in ipairs(gearAudit.CATEGORIES) do
    for _, st in ipairs(cat.stats) do
      if st == stat then return cat.key end
    end
  end
  return nil
end

-- Score `scored` restricted to one category. Reuses calculateScore's breakdown rather than
-- re-deriving the arithmetic: two implementations of the same sum WILL drift, and the one
-- nobody looks at is the one that goes wrong.
function gearAudit.categoryScore(scored, catKey)
  local _, breakdown = gearAudit.calculateScore(scored)
  local STAT_OF = {
    ["Additional Damage"] = "addDmgPct", ["Bonus Damage"] = "bonusDmgPct",
    ["Burst Damage"] = "burst",          ["Ignore Resistance"] = "ignorePct",
    ["Crit Chance"] = "critChancePct",   ["Crit Damage"] = "critDmgPct",
    ["Crit DoT"] = "critDotPct",         ["Celerity"] = "celerity",
    ["Rage Generation"] = "rageGenPct",  ["Battlerage Rage Gen"] = "brRageGenPct",
    ["Battlerage Cooldown"] = "brCooldownPct", ["Battlerage Damage"] = "brDmgPct",
    ["HP Increase"] = "hpPct",           ["HP Regen"] = "hpRegenPct",
    ["Damage Reduction"] = "dmgReductionPct", ["Resistance"] = "resistPct",
    ["Bleed Damage"] = "bleedDmgPct",    ["WP Regen"] = "wpRegenPct",
    ["Mana Regen"] = "manaRegenPct",  ["Blackout Reduction"] = "blackoutPct",
  }
  local total = 0
  for _, row in ipairs(breakdown) do
    local stat = STAT_OF[row.stat]
    if stat and gearAudit.statCategory(stat) == catKey then total = total + row.points end
  end
  return total
end

-- { [slot] = { [category] = { {gear, score}, ... sorted desc } } }
-- `topN` defaults to 3: enough to see whether the best is a clear winner or a coin toss.
function gearAudit.bisByCategory(topN)
  topN = tonumber(topN) or 3
  local out = {}
  for id, gear in pairs(gearAudit.data or {}) do
    local slot = gear.slot
    if slot and slot ~= "" then
      local scored = gearAudit.scoreEffect(gear.effects)
      out[slot] = out[slot] or {}
      for _, cat in ipairs(gearAudit.CATEGORIES) do
        local sc = gearAudit.categoryScore(scored, cat.key)
        if sc > 0 then -- an item with nothing in this category is not a candidate for it
          out[slot][cat.key] = out[slot][cat.key] or {}
          table.insert(out[slot][cat.key], { id = id, gear = gear, score = sc })
        end
      end
    end
  end
  for _, cats in pairs(out) do
    for _, items in pairs(cats) do
      table.sort(items, function(a, b)
        if a.score ~= b.score then return a.score > b.score end
        return tostring(a.id) < tostring(b.id) -- stable, so repeat runs agree
      end)
      while #items > topN do table.remove(items) end
    end
  end
  return out
end

-- Render the per-category BiS. One block per slot, one line per category, so the question
-- "what do I wear in my chest if I want rage?" is answered by looking at one line.
function gearAudit.showBisByCategory(topN)
  if not gearAudit.data or not next(gearAudit.data) then
    gearAudit.echo("No gear data. Run 'gearaudit' to collect or 'gearaudit load' to load saved data.")
    return
  end
  local bis = gearAudit.bisByCategory(topN)
  local slots = {}
  for slot in pairs(bis) do slots[#slots + 1] = slot end
  table.sort(slots)

  cecho("\n<gold>Best in Slot by CATEGORY<reset>  <grey>(a slot's best damage piece is rarely its best rage piece)<reset>\n")
  for _, slot in ipairs(slots) do
    cecho("\n<white>" .. slot:upper() .. "<reset>\n")
    local any = false
    for _, cat in ipairs(gearAudit.CATEGORIES) do
      local items = bis[slot][cat.key]
      if items and #items > 0 then
        any = true
        local parts = {}
        for i, it in ipairs(items) do
          local eff = (it.gear.summary and it.gear.summary[1])
            or (it.gear.effects and it.gear.effects[1]) or "?"
          if #eff > 34 then eff = eff:sub(1, 33) .. "." end
          -- The leader is named in full; the runners-up are there to show whether it is a
          -- clear win or a coin toss, which is the thing a single number cannot tell you.
          parts[#parts + 1] = string.format("%s<cyan>%s<reset> %s <grey>(%.0f)<reset>",
            i == 1 and "" or "  |  ", tostring(it.id), eff, it.score)
        end
        cecho(string.format("  <%s>%-10s<reset> %s\n", cat.colour, cat.label, table.concat(parts)))
      end
    end
    if not any then cecho("  <grey>nothing scored in any category<reset>\n") end
  end
  cecho("\n<grey>'gearaudit score <id>' for the breakdown behind any of these.<reset>\n")
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
        local setName = (slot == "trinket") and "N/A" or (item.gear.set or "Unknown")
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

  -- Apply slot-specific rules (e.g. hands burst/damage thresholds)
  gearAudit.applySlotRules(scraps, bySlot)

  -- Sort scraps by slot then score
  table.sort(scraps, function(a, b)
    if a.slot == b.slot then return a.score < b.score end
    return a.slot < b.slot
  end)

  return scraps
end

-- Apply slot-specific scrap rules (burst thresholds, damage floors, etc.)
function gearAudit.applySlotRules(scraps, bySlot)
  local rules = gearAudit.config.slotRules or {}

  -- Track already-scrapped IDs to avoid duplicates
  local scrappedIds = {}
  for _, s in ipairs(scraps) do
    scrappedIds[s.gear.id] = true
  end

  for slot, slotItems in pairs(bySlot) do
    local rule = rules[slot]
    if rule then
      -- Separate burst and damage items (using scored effects)
      local burstItems = {}
      for _, item in ipairs(slotItems) do
        if not scrappedIds[item.gear.id] then
          local scored = gearAudit.scoreEffect(item.gear.effects)
          if scored.burstPct then
            -- Scrap burst items under minimum threshold
            if rule.minBurstPct and scored.burstPct < rule.minBurstPct then
              table.insert(scraps, {
                gear = item.gear, score = item.score, bisScore = slotItems[1].score,
                slot = slot, set = item.gear.set or "Unknown",
                reason = string.format("Burst %d%% < %d%% min", scored.burstPct, rule.minBurstPct)
              })
              scrappedIds[item.gear.id] = true
            else
              table.insert(burstItems, { item = item, burstPct = scored.burstPct })
            end
          elseif scored.addDmgPct then
            -- Scrap damage items under minimum threshold
            if rule.minDmgPct and scored.addDmgPct < rule.minDmgPct then
              table.insert(scraps, {
                gear = item.gear, score = item.score, bisScore = slotItems[1].score,
                slot = slot, set = item.gear.set or "Unknown",
                reason = string.format("Dmg %d%% < %d%% min", scored.addDmgPct, rule.minDmgPct)
              })
              scrappedIds[item.gear.id] = true
            end
          end
        end
      end

      -- Keep only top N burst items (sorted by burst% desc)
      if rule.maxBurstKeep and #burstItems > rule.maxBurstKeep then
        table.sort(burstItems, function(a, b) return a.burstPct > b.burstPct end)
        for i = rule.maxBurstKeep + 1, #burstItems do
          local item = burstItems[i].item
          if not scrappedIds[item.gear.id] then
            table.insert(scraps, {
              gear = item.gear, score = item.score, bisScore = slotItems[1].score,
              slot = slot, set = item.gear.set or "Unknown",
              reason = string.format("Burst rank #%d (keeping top %d)", i, rule.maxBurstKeep)
            })
            scrappedIds[item.gear.id] = true
          end
        end
      end
    end
  end
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
        local setName = (item.gear.slot == "trinket") and "N/A" or (item.gear.set or "Unknown")
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
            local rarity = rarityShort(item.gear.rarity)
            local effectStr = gearAudit.summarizeEffect(item.gear.effects)

            -- Uncoloured twin of the row prefix, so continuation lines align under it
            local prefix = string.format("      #%-2d %-5s %5.1f  [%s] %-6d ",
              i, tag, item.score, rarity, item.gear.id or 0)
            local effW = math.max(gearAudit.consoleWidth() - #prefix,
                                  gearAudit.config.display.minEffects)
            local lines = gearAudit.wrapText(effectStr, effW)

            cecho(string.format(
              "\n<cyan>      #%-2d %s%-5s <yellow>%5.1f  <DimGrey>[%s] <white>%-6d <light_grey>%s",
              i, tagCol, tag, item.score, rarity,
              item.gear.id or 0, lines[1]
            ))
            for k = 2, #lines do
              cecho("\n<light_grey>" .. string.rep(" ", #prefix) .. lines[k])
            end
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
          (top.gear.slot == "trinket") and "N/A" or (top.gear.set or "Unknown")
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
  cecho(string.format("\n<cyan>| <grey>Set:<cyan>     <green>%s", (gear.slot == "trinket") and "N/A" or (gear.set or "None")))
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
    local displaySet = (s.slot == "trinket") and "N/A" or s.set
    cecho(string.format(
      "\n<red>  #%-6d <white>(%s) <green>%s <grey>- score <yellow>%.1f <grey>(BiS: <yellow>%.1f<grey>)",
      s.gear.id or 0, s.slot, displaySet, s.score, s.bisScore
    ))
    local effectStr = gearAudit.summarizeEffect(s.gear.effects)
    if #effectStr > 60 then effectStr = effectStr:sub(1, 58) .. ".." end
    local reasonStr = s.reason and (" <orange>[" .. s.reason .. "]") or ""
    cecho(string.format("\n<DimGrey>           %s <grey>- %s%s", s.gear.name or "Unknown", effectStr, reasonStr))
  end

  cecho("\n\n<cyan>--------------------------------------------------------------------------------")
  cecho(string.format("\n<white>  Scrapping %d items (1 per balance)...", #scraps))
  cecho("\n<cyan>================================================================================\n")

  -- Store queue on namespace, process one at a time gated on balance
  gearAudit.scrapQueue = {}
  for _, s in ipairs(scraps) do
    table.insert(gearAudit.scrapQueue, string.format("GEAR SCRAP %d CONFIRM", s.gear.id or 0))
  end
  gearAudit.scrapIndex = 1
  gearAudit.scrapTotal = #scraps

  -- Cleanup scrap-specific handlers
  local function scrapCleanup()
    if gearAudit.scrapEventHandler then
      killAnonymousEventHandler(gearAudit.scrapEventHandler)
      gearAudit.scrapEventHandler = nil
    end
    if gearAudit.scrapTimeoutTimer then
      killTimer(gearAudit.scrapTimeoutTimer)
      gearAudit.scrapTimeoutTimer = nil
    end
  end

  -- Process one command when balance is available
  local function processNext()
    local idx = gearAudit.scrapIndex
    if idx > gearAudit.scrapTotal then
      scrapCleanup()
      gearAudit.echo(string.format("Scrap complete. Sent %d commands.", gearAudit.scrapTotal))
      gearAudit.scrapQueue = nil
      return
    end

    -- Gate on balance (read GMCP directly to avoid handler ordering issues)
    if gmcp.Char.Vitals.bal ~= "1" then return end

    local cmd = gearAudit.scrapQueue[idx]
    cecho(string.format("\n<yellow>    [%d/%d] %s", idx, gearAudit.scrapTotal, cmd))
    send(cmd, false)
    gearAudit.scrapIndex = idx + 1

    -- Reset safety timeout for next command (10s)
    if gearAudit.scrapTimeoutTimer then killTimer(gearAudit.scrapTimeoutTimer) end
    gearAudit.scrapTimeoutTimer = tempTimer(10, function()
      scrapCleanup()
      gearAudit.echo(string.format(
        "Scrap timed out waiting for balance at item %d/%d.",
        gearAudit.scrapIndex, gearAudit.scrapTotal
      ))
      gearAudit.scrapQueue = nil
    end)
  end

  -- Register event handler: fires on every vitals update (every prompt)
  gearAudit.scrapEventHandler = registerAnonymousEventHandler(
    "gmcp.Char.Vitals",
    processNext
  )

  -- Send first command immediately
  processNext()
end

--------------------------------------------------------------------------------
-- LISTING PHASE - Parse GEAR LIST ALL output
--------------------------------------------------------------------------------

function gearAudit.setupListingTriggers()
  -- Trigger for gear list item lines
  -- Format: [*]ID    Name                          Rarity   Slot     Set         Months
  -- Example: 109     Moghedan gauntlets of piercing common   hands    moghedu     6
  -- Example: *3546   a fallen adventurer's cuirass  common   chest    adventurer  1
  -- Leading "*" marks currently worn/equipped items.
  local t1 = tempRegexTrigger(
    [[^(\*?)(\d+)\s+(.+?)\s+(common|rare|remnant|artifact|epic|legendary)\s+(\w+)\s+(\w+)\s+(\d+)\s*$]],
    function()
      local worn = (matches[2] == "*")
      local id = tonumber(matches[3])
      local name = matches[4]:match("^%s*(.-)%s*$")
      local rarity = matches[5]
      local slot = matches[6]
      local setCode = matches[7]
      local monthsLeft = tonumber(matches[8])

      if id then
        gearAudit.data[id] = gearAudit.data[id] or {}
        local g = gearAudit.data[id]
        g.id = id
        g.name = name
        g.rarity = rarity
        g.slot = slot
        g.setCode = setCode
        g.monthsLeft = monthsLeft
        g.worn = worn

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

  -- Size the fixed columns to their widest actual value, then give whatever is left
  -- to Effects. Nothing is truncated; long effect text wraps onto continuation rows.
  local rows = {}
  local idW, setW, slotW = 2, 3, 4

  for _, gear in ipairs(items) do
    local row = {
      id   = tostring(gear.id or 0),
      set  = (gear.slot == "trinket") and "N/A" or (gear.set or "Unknown"),
      slot = gear.slot or "?",
      effect = gearAudit.summarizeEffect(gear.effects),
    }
    idW   = math.max(idW,   #row.id)
    setW  = math.max(setW,  #row.set)
    slotW = math.max(slotW, #row.slot)
    table.insert(rows, row)
  end

  -- 4 borders + 8 padding spaces = 12 chars of frame around 4 columns
  local effW = gearAudit.consoleWidth() - (idW + setW + slotW + 12)
  effW = math.max(effW, gearAudit.config.display.minEffects)

  local widths = {idW, setW, slotW, effW}
  local rule = gearAudit.tableRule(widths)
  local colors = {"yellow", "green", "white", "light_grey"}

  cecho("\n<cyan>" .. rule)
  cecho("\n" .. gearAudit.tableRow(widths, {"ID", "Set", "Slot", "Effects"},
                                   {"white", "white", "white", "white"}))
  cecho("\n<cyan>" .. rule)

  for _, row in ipairs(rows) do
    -- Wrapped two narrow so the continuation indent still fits the column
    local lines = gearAudit.wrapText(row.effect, effW - 2)
    cecho("\n" .. gearAudit.tableRow(widths, {row.id, row.set, row.slot, lines[1]}, colors))
    -- Continuation rows: fixed columns blank, effect text indented two spaces
    for i = 2, #lines do
      cecho("\n" .. gearAudit.tableRow(widths, {"", "", "", "  " .. lines[i]}, colors))
    end
  end

  cecho("\n<cyan>" .. rule)
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
  cecho("\n<cyan>| <green>gearaudit cat<cyan>          - BiS per CATEGORY per slot (dmg/rage/def)  |")
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
  elseif cmd == "cat" or cmd == "categories" then
    gearAudit.showBisByCategory(rest ~= "" and tonumber(rest) or nil)
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
