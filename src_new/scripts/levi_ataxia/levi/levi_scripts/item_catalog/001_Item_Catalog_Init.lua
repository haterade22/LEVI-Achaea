--[[mudlet
type: script
name: Item Catalog Init
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
    ITEM CATALOG - INITIALIZATION
    ============================================================================
    Catalogs artefacts, talismans, promo items, and special equipment.
    Cross-references against a knowledge base to identify what each item does.
    Supports scanning from ARTEFACT LIST, TALISMAN LIST, GMCP, and PROBE.

    Loads BEFORE 002 (DB), 003 (Functions), 004 (Save/Load).
    ============================================================================
]]--

itemCatalog = itemCatalog or {}
itemCatalog.version = "1.0"

-- Discovered items: keyed by item ID (number)
-- Each entry: {id, name, location, source, kbKey, talismanSet, talismanKeyword,
--              originalName, probeText, userNote, lastSeen, identified}
itemCatalog.items = itemCatalog.items or {}

-- Configuration
itemCatalog.config = itemCatalog.config or {
  debug = false,
  probeDelay = 0.7,       -- seconds between PROBE commands
  probeUnknowns = true,   -- auto-probe items not in KB
  timeout = 120,          -- scan timeout (seconds)
}

-- Scan state (transient, not persisted)
itemCatalog.state = {
  phase = "IDLE",           -- IDLE|ARTEFACT_LIST|TALISMAN_LIST|INVENTORY|CONTAINERS|PROBING
  triggers = {},            -- temp trigger IDs for cleanup
  timers = {},              -- temp timer IDs for cleanup
  probeQueue = {},          -- queue of item IDs to auto-probe
  probeIndex = 0,
  probeCapture = {},        -- lines captured during current probe
  capturingProbe = false,
  currentProbeId = nil,
  scanStartTime = nil,
  artefactCount = 0,        -- items found in current scan phase
  talismanCount = 0,
  moreHandler = nil,        -- trigger ID for MORE pagination
}

-- Display colors (consistent with ataxia echo style)
itemCatalog.cols = {
  bracket  = "<dark_orchid>",
  label    = "<light_slate_blue>",
  text     = "<plum>",
  header   = "<cornflower_blue>",
  id       = "<dim_grey>",
  name     = "<white>",
  power    = "<cyan>",
  effect   = "<lavender>",
  set      = "<dark_sea_green>",
  unknown  = "<orange>",
  count    = "<yellow>",
  sep      = "<slate_grey>",
}

-- Items to skip during cataloging (boring consumables)
itemCatalog.skipPatterns = {
  "^a? ?stone vial$",
  "^a? ?stygian vial$",
  "^a? ?oaken vial$",
  "^a? ?obfuscated crystal vial$",
  "^a? ?elegant diamond vial$",
  "^a? ?glazed runic vial$",
  "^a? ?peridot vial$",
  "^a? ?quartz vial$",
  "^a? ?glass vial$",
  "^a? ?jade vial$",
  "^a? ?moonstone vial$",
  "^a? ?ruby vial$",
  "^a? ?sapphire crystal vial$",
  "^a? ?emerald vial$",
  "^a? ?amethyst vial$",
  "^a? ?tourmaline vial$",
  "^a? ?onyx vial$",
  "^a? ?scavenged beak pipe$",
  "^a? ?ornately carved ivory pipe$",
  "^a? ?long, elegant ebony pipe$",
  "^a? ?polished marble pipe$",
}

-- =============================================================================
-- ECHO HELPERS
-- =============================================================================

function itemCatalog.echo(text)
  local c = itemCatalog.cols
  cecho("\n" .. c.bracket .. "[" .. c.label .. "Catalog" .. c.bracket .. "]" .. c.text .. " " .. text)
end

function itemCatalog.decho(text)
  if itemCatalog.config.debug then
    itemCatalog.echo("<dim_grey>[debug] " .. text)
  end
end

function itemCatalog.echoLine(text)
  cecho("\n" .. text)
end

-- =============================================================================
-- UTILITY FUNCTIONS
-- =============================================================================

--- Strip leading articles from an item name and lowercase it
function itemCatalog.normalizeName(name)
  if not name then return "" end
  local n = name:lower()
  n = n:gsub("^the ", "")
  n = n:gsub("^an? ", "")
  n = n:gsub("%.+$", "")  -- strip trailing periods
  return n:match("^%s*(.-)%s*$") or n  -- trim whitespace
end

--- Check if an item name matches any skip pattern
function itemCatalog.shouldSkip(name)
  local normalized = itemCatalog.normalizeName(name)
  for _, pattern in ipairs(itemCatalog.skipPatterns) do
    if normalized:match(pattern) then
      return true
    end
  end
  return false
end

--- Clean up all temporary triggers and timers from a scan
function itemCatalog.cleanup()
  for _, tid in ipairs(itemCatalog.state.triggers) do
    if killTrigger then killTrigger(tid) end
  end
  for _, tid in ipairs(itemCatalog.state.timers) do
    if killTimer then killTimer(tid) end
  end
  if itemCatalog.state.moreHandler then
    if killTrigger then killTrigger(itemCatalog.state.moreHandler) end
  end
  itemCatalog.state.triggers = {}
  itemCatalog.state.timers = {}
  itemCatalog.state.moreHandler = nil
  itemCatalog.state.phase = "IDLE"
  itemCatalog.state.capturingProbe = false
  itemCatalog.state.currentProbeId = nil
  itemCatalog.state.probeCapture = {}
  itemCatalog.state.probeQueue = {}
  itemCatalog.state.probeIndex = 0
end

-- =============================================================================
-- INIT MESSAGE
-- =============================================================================

itemCatalog.echo("<cyan>Item Catalog v" .. itemCatalog.version .. "<white> initialized.")
