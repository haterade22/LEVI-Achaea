--[[mudlet
type: script
name: Item Catalog Functions
hierarchy:
- Levi_Ataxia
- LEVI
- Levi  Scripts
- Item Catalog
attributes:
  isActive: 'yes'
  isFolder: 'no'
packageName: ''
]]--

--[[
    ============================================================================
    ITEM CATALOG - CORE FUNCTIONS
    ============================================================================
    Scanning, matching, display, search, and command dispatch.
    ============================================================================
]]--

itemCatalog = itemCatalog or {}

-- =============================================================================
-- KB MATCHING
-- =============================================================================

--- Look up an item name in the knowledge base.
--- Returns the KB entry table or nil.
function itemCatalog.lookup(name)
  if not name then return nil end
  local normalized = itemCatalog.normalizeName(name)
  if itemCatalog.kb[normalized] then
    return itemCatalog.kb[normalized], normalized
  end
  -- Try partial match: check if any KB key is contained in the name
  for key, entry in pairs(itemCatalog.kb) do
    if normalized:find(key, 1, true) then
      return entry, key
    end
  end
  return nil, nil
end

--- Register or update an item in the catalog.
function itemCatalog.registerItem(id, name, opts)
  local numId = tonumber(id)
  if not numId or not name then return end
  opts = opts or {}

  local existing = itemCatalog.items[numId] or {}
  local _, kbKey = itemCatalog.lookup(name)

  itemCatalog.items[numId] = {
    id            = numId,
    name          = name,
    location      = opts.location or existing.location or "unknown",
    source        = opts.source or existing.source or "manual",
    kbKey         = kbKey or existing.kbKey,
    talismanSet   = opts.talismanSet or existing.talismanSet,
    talismanKeyword = opts.talismanKeyword or existing.talismanKeyword,
    originalName  = opts.originalName or existing.originalName,
    probeText     = opts.probeText or existing.probeText,
    userNote      = existing.userNote,  -- never overwrite user notes
    lastSeen      = os.time(),
    identified    = (kbKey ~= nil) or (existing.identified == true),
  }
  return itemCatalog.items[numId]
end

-- =============================================================================
-- SCAN ORCHESTRATION
-- =============================================================================

--- Start a full scan (ARTEFACT LIST -> TALISMAN LIST -> GMCP -> containers -> probe)
function itemCatalog.startScan(quickMode)
  if itemCatalog.state.phase ~= "IDLE" then
    itemCatalog.echo("Scan already in progress (" .. itemCatalog.state.phase .. "). Use <white>catalog stop<plum> to cancel.")
    return
  end

  itemCatalog.state.scanStartTime = os.time()
  itemCatalog.state.artefactCount = 0
  itemCatalog.state.talismanCount = 0
  itemCatalog.state.quickMode = quickMode or false

  itemCatalog.echo("Starting " .. (quickMode and "quick" or "full") .. " scan...")
  itemCatalog.startArtefactListScan()
end

--- Stop any in-progress scan.
function itemCatalog.stopScan()
  if itemCatalog.state.phase == "IDLE" then
    itemCatalog.echo("No scan in progress.")
    return
  end
  itemCatalog.echo("Scan stopped.")
  itemCatalog.cleanup()
end

-- =============================================================================
-- PHASE 1: ARTEFACT LIST
-- =============================================================================

function itemCatalog.startArtefactListScan()
  itemCatalog.state.phase = "ARTEFACT_LIST"
  itemCatalog.state.artefactCount = 0

  -- Header trigger (skip the header line and dashes)
  local headerTrigger = tempRegexTrigger(
    [[^Item\s+Name\s+Originally]],
    function() end
  )
  table.insert(itemCatalog.state.triggers, headerTrigger)

  local dashTrigger = tempRegexTrigger(
    [[^-{10,}]],
    function() end
  )
  table.insert(itemCatalog.state.triggers, dashTrigger)

  -- Data line trigger: captures ID, name, originalName
  local dataTrigger = tempRegexTrigger(
    [[^\s+(\d+)\s{2,}(.+?)\s{2,}(\S.*)$]],
    function()
      local id = matches[2]
      local name = matches[3]:match("^%s*(.-)%s*$")
      local orig = matches[4]:match("^%s*(.-)%s*$")

      if not itemCatalog.shouldSkip(name) then
        itemCatalog.registerItem(id, name, {
          source = "artefact_list",
          originalName = orig,
        })
        itemCatalog.state.artefactCount = itemCatalog.state.artefactCount + 1
      end
    end
  )
  table.insert(itemCatalog.state.triggers, dataTrigger)

  -- MORE pagination handler
  itemCatalog.state.moreHandler = tempRegexTrigger(
    [[^\[Type MORE if you wish to continue reading]],
    function()
      send("MORE", false)
    end
  )

  -- End detection: blank prompt or specific end text
  -- Use a timer to detect end of output (no new line for 2 seconds)
  local endTimer
  local function resetEndTimer()
    if endTimer then killTimer(endTimer) end
    endTimer = tempTimer(2.0, function()
      itemCatalog.decho("ARTEFACT LIST complete: " .. itemCatalog.state.artefactCount .. " items")
      itemCatalog.echo("Artefacts found: <white>" .. itemCatalog.state.artefactCount)
      -- Clean up phase 1 triggers
      for _, tid in ipairs(itemCatalog.state.triggers) do
        killTrigger(tid)
      end
      itemCatalog.state.triggers = {}
      if itemCatalog.state.moreHandler then
        killTrigger(itemCatalog.state.moreHandler)
        itemCatalog.state.moreHandler = nil
      end
      if endTimer then killTimer(endTimer) end
      -- Move to phase 2
      itemCatalog.startTalismanListScan()
    end)
  end

  -- Reset end timer on each data line
  local resetTrigger = tempRegexTrigger(
    [[^\s+\d+\s{2,}]],
    function()
      resetEndTimer()
    end
  )
  table.insert(itemCatalog.state.triggers, resetTrigger)

  -- Send the command
  send("ARTEFACT LIST", false)
  resetEndTimer()
end

-- =============================================================================
-- PHASE 2: TALISMAN LIST
-- =============================================================================

function itemCatalog.startTalismanListScan()
  itemCatalog.state.phase = "TALISMAN_LIST"
  itemCatalog.state.talismanCount = 0

  -- Header/dash skip
  local headerTrigger = tempRegexTrigger(
    [[^Name\s+Set\s+Keyword]],
    function() end
  )
  table.insert(itemCatalog.state.triggers, headerTrigger)

  local dashTrigger = tempRegexTrigger(
    [[^-{10,}]],
    function() end
  )
  table.insert(itemCatalog.state.triggers, dashTrigger)

  -- Data line: name, set, keyword
  local dataTrigger = tempRegexTrigger(
    [[^(.+?)\s{2,}(\S+)\s{2,}(\S+)\s*$]],
    function()
      local name = matches[2]:match("^%s*(.-)%s*$")
      local tSet = matches[3]:match("^%s*(.-)%s*$")
      local keyword = matches[4]:match("^%s*(.-)%s*$")

      -- Look up in talisman KB
      local tkbEntry = itemCatalog.talismanKB[keyword]

      -- Try to find matching item by name in existing catalog
      local foundId = nil
      for id, item in pairs(itemCatalog.items) do
        if itemCatalog.normalizeName(item.name) == itemCatalog.normalizeName(name) then
          foundId = id
          break
        end
      end

      if foundId then
        -- Update existing entry with talisman info
        local item = itemCatalog.items[foundId]
        item.talismanSet = tSet
        item.talismanKeyword = keyword
        item.source = item.source or "talisman_list"
        if tkbEntry and not item.identified then
          item.identified = true
        end
      else
        -- Register as new (we don't have an ID from talisman list, use keyword as temp key)
        -- Talisman list doesn't give IDs, so we store by keyword temporarily
        itemCatalog.decho("Talisman not in artefact list: " .. name .. " [" .. keyword .. "]")
      end

      itemCatalog.state.talismanCount = itemCatalog.state.talismanCount + 1
    end
  )
  table.insert(itemCatalog.state.triggers, dataTrigger)

  -- MORE pagination
  itemCatalog.state.moreHandler = tempRegexTrigger(
    [[^\[Type MORE if you wish to continue reading]],
    function()
      send("MORE", false)
    end
  )

  -- End detection timer
  local endTimer
  local function resetEndTimer()
    if endTimer then killTimer(endTimer) end
    endTimer = tempTimer(2.0, function()
      itemCatalog.echo("Talismans found: <white>" .. itemCatalog.state.talismanCount)
      for _, tid in ipairs(itemCatalog.state.triggers) do
        killTrigger(tid)
      end
      itemCatalog.state.triggers = {}
      if itemCatalog.state.moreHandler then
        killTrigger(itemCatalog.state.moreHandler)
        itemCatalog.state.moreHandler = nil
      end
      if endTimer then killTimer(endTimer) end

      if itemCatalog.state.quickMode then
        itemCatalog.finishScan()
      else
        itemCatalog.startProbePhase()
      end
    end)
  end

  local resetTrigger = tempRegexTrigger(
    [[^.+?\s{2,}\S+\s{2,}\S+\s*$]],
    function()
      resetEndTimer()
    end
  )
  table.insert(itemCatalog.state.triggers, resetTrigger)

  send("TALISMAN LIST", false)
  resetEndTimer()
end

-- =============================================================================
-- PHASE 3: AUTO-PROBE UNKNOWNS
-- =============================================================================

function itemCatalog.startProbePhase()
  if not itemCatalog.config.probeUnknowns then
    itemCatalog.finishScan()
    return
  end

  itemCatalog.state.phase = "PROBING"
  itemCatalog.state.probeQueue = {}
  itemCatalog.state.probeIndex = 0

  -- Build queue of unidentified items
  for id, item in pairs(itemCatalog.items) do
    if not item.identified and not item.probeText then
      table.insert(itemCatalog.state.probeQueue, id)
    end
  end

  if #itemCatalog.state.probeQueue == 0 then
    itemCatalog.echo("No unknown items to probe.")
    itemCatalog.finishScan()
    return
  end

  itemCatalog.echo("Probing <white>" .. #itemCatalog.state.probeQueue .. "<plum> unknown items...")
  itemCatalog.probeNext()
end

function itemCatalog.probeNext()
  itemCatalog.state.probeIndex = itemCatalog.state.probeIndex + 1
  if itemCatalog.state.probeIndex > #itemCatalog.state.probeQueue then
    -- Done probing
    for _, tid in ipairs(itemCatalog.state.triggers) do
      killTrigger(tid)
    end
    itemCatalog.state.triggers = {}
    itemCatalog.finishScan()
    return
  end

  local id = itemCatalog.state.probeQueue[itemCatalog.state.probeIndex]
  itemCatalog.state.currentProbeId = id
  itemCatalog.state.probeCapture = {}
  itemCatalog.state.capturingProbe = true

  -- Clean old probe triggers
  for _, tid in ipairs(itemCatalog.state.triggers) do
    killTrigger(tid)
  end
  itemCatalog.state.triggers = {}

  -- Capture all lines during probe
  local captureTrigger = tempRegexTrigger(
    [[^.+$]],
    function()
      if itemCatalog.state.capturingProbe then
        table.insert(itemCatalog.state.probeCapture, matches[1])
      end
    end
  )
  table.insert(itemCatalog.state.triggers, captureTrigger)

  -- End probe after 1.5s of no new output
  local probeEndTimer
  local function resetProbeEnd()
    if probeEndTimer then killTimer(probeEndTimer) end
    probeEndTimer = tempTimer(1.5, function()
      itemCatalog.state.capturingProbe = false
      local pid = itemCatalog.state.currentProbeId
      if pid and itemCatalog.items[pid] then
        itemCatalog.items[pid].probeText = table.concat(itemCatalog.state.probeCapture, "\n")
      end
      -- Probe next after delay
      tempTimer(itemCatalog.config.probeDelay, function()
        itemCatalog.probeNext()
      end)
    end)
  end

  -- Reset timer on each captured line
  local resetTrigger = tempRegexTrigger(
    [[^.+$]],
    function()
      if itemCatalog.state.capturingProbe then
        resetProbeEnd()
      end
    end
  )
  table.insert(itemCatalog.state.triggers, resetTrigger)

  send("PROBE " .. id, false)
  resetProbeEnd()
end

-- =============================================================================
-- SCAN COMPLETION
-- =============================================================================

function itemCatalog.finishScan()
  local elapsed = os.time() - (itemCatalog.state.scanStartTime or os.time())

  -- Count by type
  local counts = { artefact=0, talisman=0, promo=0, special=0, unknown=0 }
  local total = 0
  for _, item in pairs(itemCatalog.items) do
    total = total + 1
    if item.kbKey then
      local kb = itemCatalog.kb[item.kbKey]
      if kb then
        local t = kb.type or "unknown"
        counts[t] = (counts[t] or 0) + 1
      else
        counts.unknown = counts.unknown + 1
      end
    else
      counts.unknown = counts.unknown + 1
    end
  end

  local c = itemCatalog.cols
  itemCatalog.echo(c.header .. "Scan complete" .. c.text .. " (" .. elapsed .. "s)")
  itemCatalog.echo("Total: " .. c.count .. total .. c.text
    .. " | Artefacts: " .. c.count .. counts.artefact
    .. c.text .. " | Talismans: " .. c.count .. (counts.talisman or 0)
    .. c.text .. " | Promo: " .. c.count .. (counts.promo or 0)
    .. c.text .. " | Special: " .. c.count .. (counts.special or 0)
    .. c.text .. " | Unknown: " .. c.count .. (counts.unknown or 0))

  itemCatalog.cleanup()
  itemCatalog.save()
end

-- =============================================================================
-- DISPLAY FUNCTIONS
-- =============================================================================

--- Display all cataloged items, optionally filtered by type.
function itemCatalog.show(filterType)
  local c = itemCatalog.cols

  -- Group items by type then category
  local grouped = {}  -- type -> category -> {items}
  local total = 0
  local typeCounts = {}

  for _, item in pairs(itemCatalog.items) do
    local kbEntry = item.kbKey and itemCatalog.kb[item.kbKey]
    local itype = kbEntry and kbEntry.type or "unknown"
    local icat = kbEntry and kbEntry.category or "unknown"

    if not filterType or itype == filterType then
      grouped[itype] = grouped[itype] or {}
      grouped[itype][icat] = grouped[itype][icat] or {}
      table.insert(grouped[itype][icat], { item=item, kb=kbEntry })
      total = total + 1
      typeCounts[itype] = (typeCounts[itype] or 0) + 1
    end
  end

  if total == 0 then
    itemCatalog.echo("No items to display." .. (filterType and (" Filter: " .. filterType) or "") .. " Run <white>catalog scan<plum> first.")
    return
  end

  -- Header
  itemCatalog.echoLine(c.header .. string.rep("=", 70))
  itemCatalog.echoLine(c.header .. "  ITEM CATALOG" .. c.sep .. "  (" .. total .. " items)")
  itemCatalog.echoLine(c.header .. string.rep("=", 70))

  -- Display order for types
  local typeOrder = {"artefact", "talisman", "promo", "special", "unknown"}
  local typeLabels = { artefact="ARTEFACTS", talisman="TALISMANS", promo="PROMO ITEMS", special="SPECIAL ITEMS", unknown="UNKNOWN" }

  for _, itype in ipairs(typeOrder) do
    if grouped[itype] then
      local tcount = typeCounts[itype] or 0
      itemCatalog.echoLine("")
      itemCatalog.echoLine(c.header .. "  --- " .. typeLabels[itype] .. " (" .. tcount .. ") " .. string.rep("-", 50 - #typeLabels[itype]))

      -- Sub-group by category
      for _, cat in ipairs(itemCatalog.categoryOrder) do
        if grouped[itype][cat] then
          local catLabel = itemCatalog.categoryLabels[cat] or cat
          itemCatalog.echoLine(c.set .. "    " .. catLabel)

          -- Sort items by ID
          local items = grouped[itype][cat]
          table.sort(items, function(a, b) return a.item.id < b.item.id end)

          for _, entry in ipairs(items) do
            itemCatalog.displayItemLine(entry.item, entry.kb)
          end
        end
      end

      -- Handle "unknown" category items
      if grouped[itype]["unknown"] then
        itemCatalog.echoLine(c.set .. "    Uncategorized")
        local items = grouped[itype]["unknown"]
        table.sort(items, function(a, b) return a.item.id < b.item.id end)
        for _, entry in ipairs(items) do
          itemCatalog.displayItemLine(entry.item, entry.kb)
        end
      end
    end
  end

  -- Footer
  itemCatalog.echoLine("")
  itemCatalog.echoLine(c.sep .. string.rep("-", 70))

  local parts = {}
  for _, t in ipairs(typeOrder) do
    if typeCounts[t] and typeCounts[t] > 0 then
      table.insert(parts, typeLabels[t]:lower() .. ": " .. c.count .. typeCounts[t] .. c.text)
    end
  end
  itemCatalog.echoLine(c.text .. "  Total: " .. c.count .. total .. c.text .. " | " .. table.concat(parts, " | "))
end

--- Display a single item line in the catalog view.
function itemCatalog.displayItemLine(item, kb)
  local c = itemCatalog.cols
  local idStr = string.format("%7d", item.id)
  local nameStr = itemCatalog.normalizeName(item.name)
  if #nameStr > 26 then nameStr = nameStr:sub(1, 24) .. ".." end
  nameStr = string.format("%-26s", nameStr)

  local powerStr, effectStr
  if kb then
    local p = kb.power or ""
    if kb.tier then p = p .. " L" .. kb.tier end
    powerStr = string.format("%-18s", p)
    effectStr = kb.effect or ""
  elseif item.talismanKeyword then
    powerStr = string.format("%-18s", item.talismanKeyword)
    local tkb = itemCatalog.talismanKB[item.talismanKeyword]
    effectStr = tkb and tkb.effect or "[talisman]"
  else
    powerStr = string.format("%-18s", "")
    effectStr = item.probeText and "[probed - needs review]" or "[unknown]"
  end

  if #effectStr > 40 then effectStr = effectStr:sub(1, 38) .. ".." end

  local prefix = (not item.identified and not kb) and (c.unknown .. "  *") or "   "
  itemCatalog.echoLine(prefix .. c.id .. idStr .. "  " .. c.name .. nameStr .. " " .. c.power .. powerStr .. " " .. c.effect .. effectStr)
end

--- Display full details for a specific item.
function itemCatalog.showInfo(idStr)
  local id = tonumber(idStr)
  if not id then
    itemCatalog.echo("Usage: catalog info <id>")
    return
  end

  local item = itemCatalog.items[id]
  if not item then
    itemCatalog.echo("Item " .. id .. " not found in catalog.")
    return
  end

  local c = itemCatalog.cols
  local kb = item.kbKey and itemCatalog.kb[item.kbKey]

  itemCatalog.echoLine(c.header .. string.rep("=", 60))
  itemCatalog.echoLine(c.header .. "  ITEM DETAILS: " .. c.name .. item.name)
  itemCatalog.echoLine(c.header .. string.rep("=", 60))
  itemCatalog.echoLine(c.text .. "  ID:       " .. c.count .. item.id)
  itemCatalog.echoLine(c.text .. "  Name:     " .. c.name .. item.name)
  itemCatalog.echoLine(c.text .. "  Location: " .. c.name .. (item.location or "unknown"))
  itemCatalog.echoLine(c.text .. "  Source:   " .. c.sep .. (item.source or "unknown"))

  if item.originalName and item.originalName ~= "N/A" then
    itemCatalog.echoLine(c.text .. "  Original: " .. c.sep .. item.originalName)
  end

  if kb then
    itemCatalog.echoLine("")
    itemCatalog.echoLine(c.text .. "  Type:     " .. c.power .. (kb.type or ""))
    itemCatalog.echoLine(c.text .. "  Category: " .. c.set .. (itemCatalog.categoryLabels[kb.category] or kb.category or ""))
    itemCatalog.echoLine(c.text .. "  Power:    " .. c.power .. (kb.power or ""))
    if kb.tier then
      itemCatalog.echoLine(c.text .. "  Tier:     " .. c.count .. kb.tier)
    end
    if kb.credits then
      itemCatalog.echoLine(c.text .. "  Credits:  " .. c.count .. kb.credits)
    end
    itemCatalog.echoLine(c.text .. "  Effect:   " .. c.effect .. (kb.effect or ""))
  end

  if item.talismanSet then
    itemCatalog.echoLine("")
    itemCatalog.echoLine(c.text .. "  Talisman Set: " .. c.set .. item.talismanSet)
    itemCatalog.echoLine(c.text .. "  Keyword:      " .. c.power .. (item.talismanKeyword or ""))
    local tkb = item.talismanKeyword and itemCatalog.talismanKB[item.talismanKeyword]
    if tkb then
      itemCatalog.echoLine(c.text .. "  Tali Effect:  " .. c.effect .. tkb.effect)
    end
  end

  if item.userNote then
    itemCatalog.echoLine("")
    itemCatalog.echoLine(c.text .. "  Note:     " .. c.name .. item.userNote)
  end

  if item.probeText then
    itemCatalog.echoLine("")
    itemCatalog.echoLine(c.sep .. "  --- Probe Text ---")
    for line in item.probeText:gmatch("[^\n]+") do
      itemCatalog.echoLine(c.sep .. "  " .. line)
    end
  end

  itemCatalog.echoLine(c.header .. string.rep("=", 60))
end

-- =============================================================================
-- SEARCH
-- =============================================================================

function itemCatalog.search(query)
  if not query or query == "" then
    itemCatalog.echo("Usage: catalog search <keyword>")
    return
  end

  local q = query:lower()
  local results = {}

  for _, item in pairs(itemCatalog.items) do
    local found = false
    local kb = item.kbKey and itemCatalog.kb[item.kbKey]

    -- Search item name
    if item.name and item.name:lower():find(q, 1, true) then found = true end
    -- Search KB fields
    if kb then
      if kb.power and kb.power:lower():find(q, 1, true) then found = true end
      if kb.effect and kb.effect:lower():find(q, 1, true) then found = true end
      if kb.category and kb.category:lower():find(q, 1, true) then found = true end
      if kb.type and kb.type:lower():find(q, 1, true) then found = true end
    end
    -- Search talisman fields
    if item.talismanSet and item.talismanSet:lower():find(q, 1, true) then found = true end
    if item.talismanKeyword and item.talismanKeyword:lower():find(q, 1, true) then found = true end
    -- Search user note
    if item.userNote and item.userNote:lower():find(q, 1, true) then found = true end

    if found then
      table.insert(results, { item=item, kb=kb })
    end
  end

  if #results == 0 then
    itemCatalog.echo("No items matching '<white>" .. query .. "<plum>'.")
    return
  end

  local c = itemCatalog.cols
  itemCatalog.echo("Search results for '<white>" .. query .. "<plum>': " .. c.count .. #results .. c.text .. " found")
  itemCatalog.echoLine("")

  table.sort(results, function(a, b) return a.item.id < b.item.id end)
  for _, entry in ipairs(results) do
    itemCatalog.displayItemLine(entry.item, entry.kb)
  end
end

-- =============================================================================
-- UNKNOWNS
-- =============================================================================

function itemCatalog.showUnknowns()
  local c = itemCatalog.cols
  local unknowns = {}

  for _, item in pairs(itemCatalog.items) do
    if not item.identified then
      local kb = item.kbKey and itemCatalog.kb[item.kbKey]
      table.insert(unknowns, { item=item, kb=kb })
    end
  end

  if #unknowns == 0 then
    itemCatalog.echo("All items are identified!")
    return
  end

  itemCatalog.echo("Unidentified items: " .. c.count .. #unknowns)
  itemCatalog.echoLine("")

  table.sort(unknowns, function(a, b) return a.item.id < b.item.id end)
  for _, entry in ipairs(unknowns) do
    local item = entry.item
    local status = item.probeText and "[probed - needs review]" or "[not probed]"
    itemCatalog.echoLine(c.unknown .. "  * " .. c.id .. string.format("%7d", item.id) .. "  " .. c.name .. item.name .. "  " .. c.sep .. status)
  end
  itemCatalog.echoLine("")
  itemCatalog.echo("Use <white>catalog note <id> <text><plum> to annotate items.")
end

-- =============================================================================
-- USER NOTES
-- =============================================================================

function itemCatalog.addNote(args)
  if not args or args == "" then
    itemCatalog.echo("Usage: catalog note <id> <text>")
    return
  end

  local id, note = args:match("^(%d+)%s+(.+)$")
  if not id or not note then
    itemCatalog.echo("Usage: catalog note <id> <text>")
    return
  end

  local numId = tonumber(id)
  if not itemCatalog.items[numId] then
    itemCatalog.echo("Item " .. id .. " not found in catalog.")
    return
  end

  itemCatalog.items[numId].userNote = note
  itemCatalog.items[numId].identified = true  -- User has reviewed it
  itemCatalog.save()
  itemCatalog.echo("Note added to " .. itemCatalog.items[numId].name .. ": <white>" .. note)
end

-- =============================================================================
-- HELP
-- =============================================================================

function itemCatalog.showHelp()
  local c = itemCatalog.cols
  itemCatalog.echoLine(c.header .. string.rep("=", 60))
  itemCatalog.echoLine(c.header .. "  ITEM CATALOG v" .. itemCatalog.version .. " - Commands")
  itemCatalog.echoLine(c.header .. string.rep("=", 60))
  itemCatalog.echoLine(c.name .. "  catalog scan        " .. c.text .. "Full scan (artefact list + talisman list + probe)")
  itemCatalog.echoLine(c.name .. "  catalog quick       " .. c.text .. "Quick scan (artefact + talisman list only)")
  itemCatalog.echoLine(c.name .. "  catalog show        " .. c.text .. "Display all cataloged items")
  itemCatalog.echoLine(c.name .. "  catalog show <type> " .. c.text .. "Filter: artefact, talisman, promo, special, unknown")
  itemCatalog.echoLine(c.name .. "  catalog search <q>  " .. c.text .. "Search by name, power, effect, set")
  itemCatalog.echoLine(c.name .. "  catalog info <id>   " .. c.text .. "Full details for one item")
  itemCatalog.echoLine(c.name .. "  catalog note <id> <text>" .. c.text .. " Add/update manual note")
  itemCatalog.echoLine(c.name .. "  catalog unknowns    " .. c.text .. "List unidentified items")
  itemCatalog.echoLine(c.name .. "  catalog save        " .. c.text .. "Manual save to disk")
  itemCatalog.echoLine(c.name .. "  catalog load        " .. c.text .. "Manual load from disk")
  itemCatalog.echoLine(c.name .. "  catalog stop        " .. c.text .. "Stop in-progress scan")
  itemCatalog.echoLine(c.name .. "  catalog help        " .. c.text .. "This help")
  itemCatalog.echoLine(c.header .. string.rep("=", 60))
end

-- =============================================================================
-- COMMAND DISPATCHER
-- =============================================================================

function itemCatalog.command(input)
  input = input or ""
  local cmd, rest = input:match("^(%S+)%s*(.*)$")
  if not cmd then cmd = "" end
  cmd = cmd:lower()

  if cmd == "scan" or cmd == "start" then
    itemCatalog.startScan(false)
  elseif cmd == "quick" then
    itemCatalog.startScan(true)
  elseif cmd == "stop" or cmd == "cancel" then
    itemCatalog.stopScan()
  elseif cmd == "show" or cmd == "list" or cmd == "display" then
    local filterType = rest ~= "" and rest:lower() or nil
    -- Normalize filter aliases
    if filterType == "artefacts" or filterType == "artifacts" then filterType = "artefact" end
    if filterType == "talismans" then filterType = "talisman" end
    if filterType == "promos" then filterType = "promo" end
    if filterType == "specials" then filterType = "special" end
    if filterType == "unknowns" then filterType = "unknown" end
    itemCatalog.show(filterType)
  elseif cmd == "search" or cmd == "find" then
    itemCatalog.search(rest)
  elseif cmd == "info" or cmd == "detail" or cmd == "details" then
    itemCatalog.showInfo(rest)
  elseif cmd == "note" or cmd == "annotate" then
    itemCatalog.addNote(rest)
  elseif cmd == "unknowns" or cmd == "unknown" then
    itemCatalog.showUnknowns()
  elseif cmd == "save" then
    itemCatalog.save()
    itemCatalog.echo("Catalog saved to disk.")
  elseif cmd == "load" then
    itemCatalog.load()
    itemCatalog.echo("Catalog loaded from disk.")
  elseif cmd == "help" or cmd == "" then
    itemCatalog.showHelp()
  else
    itemCatalog.echo("Unknown command: <white>" .. cmd .. "<plum>. Type <white>catalog help<plum> for usage.")
  end
end
