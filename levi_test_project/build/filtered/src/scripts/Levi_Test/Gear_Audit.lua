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
  gearAudit.echo("Saved " .. gearAudit.tableSize(gearAudit.data) .. " gear items to disk.")
end

function gearAudit.load()
  local separator = package.config:sub(1, 1)
  local filepath = getMudletHomeDir() .. separator .. gearAudit.config.saveFile
  if io.exists(filepath) then
    gearAudit.data = {}
    table.load(filepath, gearAudit.data)
    gearAudit.echo("Loaded " .. gearAudit.tableSize(gearAudit.data) .. " gear items from disk.")
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
    cecho("\n<cyan>|   <dark_grey>(No effects recorded)")
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
