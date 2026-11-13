--[[mudlet
type: script
name: Artefacts
hierarchy:
- Levi_Ataxia
- LEVI
- Ataxia
- Misc Scripts
attributes:
  isActive: 'yes'
  isFolder: 'no'
packageName: ''
]]--

-- OUR ARTEFACTS, from ARTEFACT POWER LIST OWNED (v4.7.494). A player's report (2026-11-13): "in our
-- documentation and logic we are not factoring in artefacts we have. A diadem artefact reduces eq
-- balance." Our numbers came from the wiki (no artefacts) or from other players' logs (their
-- artefacts, unknown), and no code asked which artefacts THIS character owns.
--
-- The game's list, as the user pasted it (kb/raw/live/artefact_power_list_owned_2026-11-13.txt):
--   Item ID       Item Name                           Power                Level
--   -------------------------------------------------------------------------------
--   385702        an Aldar Diadem                     faster_eq              2
--   442098        a gem of haematite with elemental f rapid_resonation       -
--   212547        a stone of the lesser lorewarden    class_switch_reducti   3
-- The name column is cut at 35 characters and can run into the power with ONE space, and the power
-- column is cut at 20 characters. So a row is read from its END: the last word is the level ("-" =
-- the power has no levels), the word before it the power, the first word the id. A cut power is
-- matched to its full name by prefix (powerKey).
--
-- Trigger 802 reads the header row and opens a short window; trigger 803 reads each row only inside
-- that window, so a line of numbers in any other output is never taken for an artefact (the trait
-- list's shape, misc_scripts/031). The list is SAVED (ataxia.settings.artefacts), so one reading
-- lasts; login asks for it only while none is saved, and `aconfig artefact scan` reads it again.
--
-- OWNED = ACTIVE, unless the user switches a power off (`aconfig artefact <power> off`). The user,
-- 2026-11-13: the diadem is worn at all times. GMCP cannot tell worn from carried, and the catalog
-- never records it (item_catalog/003 registerItem: location is always "unknown").
--
-- Never scanned: the item catalog stands in (`catalog scan` keys each artefact to a KB entry with its
-- power and tier, item_catalog/002). Neither: no artefact, so every reader keeps its old number.

ataxia = ataxia or {}
ataxia.settings = ataxia.settings or {}
ataxiaTemp = ataxiaTemp or {}
ataxiaArtefacts = ataxiaArtefacts or {}
local A = ataxiaArtefacts

local WINDOW = 10 -- seconds after the header, or the last row, in which rows are read

-- What each power changes, per level, and who reads it. Sizes are from docs/artefacts-reference.md
-- (the game's ARTEFACT POWER SHOW text replaces them once `kbcapture artefacts` has run). `ours`
-- says what our own logs show, where they show it.
A.EFFECTS = {
  faster_eq = { what = "faster equilibrium recovery", pct = { 7, 15 },
    ours = "level 2: every eq cost x0.85 in our logs (kb/mechanics/balance-and-queueing.md)",
    reader = "ataxia_eqFactor" },
  criticals = { what = "critical hit chance", pct = { 2, 4, 6 }, reader = "docs only" },
  magic_damage = { what = "magical damage", pct = { 10, 15, 20 }, reader = "docs only" },
  hand_to_hand = { what = "Tekura punch damage", pct = { 15, 25, 35 },
    reader = "tekura/001 + 002 learn the punch damage" },
  weaving_mastery = { what = "weaving damage", pct = { 10, 15, 20 }, reader = "docs only" },
  swiftcurse = { what = "SWIFTCURSE curses (and JINX seconds)", add = { 2, 4, 6 },
    reader = "shaman/011, genrunning/004 (curse count fallback)" },
  enhanced_shin = { what = "HAMSTRING seconds, ANNIHILATE chance", add = { 5 },
    reader = "docs only until ARTEFACT POWER SHOW confirms" },
  tuning = { what = "lifetime of vibrations, harmonics and rites", mult = { 2 },
    reader = "docs only until ARTEFACT POWER SHOW confirms" },
  symphonic_master = { what = "faster equilibrium for PLAY harmonics", pct = { 50 }, reader = "docs only" },
  rapid_resonation = { what = "less equilibrium for crystalism EMBED", pct = { 50 }, reader = "docs only" },
  swift_runes = { what = "faster rune sketching", pct = { 33 }, reader = "docs only" },
  faster_mindlock = { what = "faster MINDLOCK", pct = { 40 }, reader = "docs only" },
  primordial_fury = { what = "TITAN +5 s, 30% less cooldown", reader = "not modelled" },
  grasping_death = { what = "GRAVEHANDS duration", pct = { 50 }, reader = "not modelled" },
  pure_song = { what = "ARIA duration", mult = { 2 }, reader = "not modelled (SSC cures it)" },
  unending_avalanche = { what = "ROCKSLIDE rubble duration", pct = { 50 }, reader = "not modelled" },
  unyielding_stone = { what = "POWDERISE limb damage", pct = { 10 }, reader = "not modelled" },
  shin_drain = { what = "slower shin decay", reader = "not modelled" },
  battlerage_decay = { what = "slower battlerage decay", reader = "not modelled" },
  quickmount = { what = "faster mount balance", reader = "not modelled" },
  faster_inscribe = { what = "faster tarot inscribing", reader = "not modelled" },
  faster_commune = { what = "faster commune", reader = "not modelled" },
}
-- An artefact Shikudo staff has no power name we know, so it is not here: its level is the manual
-- `aconfig shikstaff` setting (ataxia.shikudoLevel), read by shikudo/006 getAttackDamage.

-- Rain (Shikudo) on top of every other factor: about x0.85 more. Our logs: MIND IMPATIENCE 1.07 s in
-- Rain against 1.27 s in other forms, MIND DISRUPT 2.89 s, MIND CRUSH 2.45 s (kb/combat/shikudo.md).
A.RAIN_FACTOR = 0.85

local function norm(s)
  return (tostring(s or ""):gsub("^%s+", ""):gsub("%s+$", ""):lower())
end

local function store()
  local s = ataxia.settings.artefacts
  if type(s) ~= "table" then
    s = {}
    ataxia.settings.artefacts = s
  end
  s.override = type(s.override) == "table" and s.override or {}
  return s
end

-- The full power name for a cut one ("class_switch_reducti" -> "class_switch_reduction" when a full
-- name we know starts with it). Unknown names stay as they are.
function ataxia_artefactPowerKey(p)
  p = norm(p)
  if p == "" or A.EFFECTS[p] then return p end
  local function fits(full) return #full > #p and full:sub(1, #p) == p end
  for full in pairs(A.EFFECTS) do
    if fits(full) then return full end
  end
  if type(itemCatalog) == "table" and type(itemCatalog.kb) == "table" then
    for _, e in pairs(itemCatalog.kb) do
      if type(e) == "table" and type(e.power) == "string" and fits(e.power) then return e.power end
    end
  end
  return p
end

-- One row of ARTEFACT POWER LIST OWNED -> id, name, power, level (a number, or nil for "-").
-- nil for anything else (the header, the dashed rules, a blank line).
function ataxia_parseArtefactPowerRow(line)
  if type(line) ~= "string" then return nil end
  local id, name, power, level = line:match("^%s*(%d+)%s+(.-)%s+(%S+)%s+(%S+)%s*$")
  if not id or name == "" then return nil end
  if not power:match("^[%a_]+$") then return nil end
  if level ~= "-" and not level:match("^%d+$") then return nil end
  return tonumber(id), name, ataxia_artefactPowerKey(power), tonumber(level)
end

-- Every row in a block of lines -> { [power] = { id, name, level } }, and how many rows. A power on
-- two items (Suremekh'neina has health_regen and mana_regen; one power can sit on two items) keeps
-- the highest level.
function ataxia_artefactsFromLines(lines)
  local out, n = {}, 0
  for _, l in ipairs(lines or {}) do
    local id, name, power, level = ataxia_parseArtefactPowerRow(l)
    if id then
      n = n + 1
      local had = out[power]
      if not had or (level or 0) > (had.level or 0) then
        out[power] = { id = id, name = name, level = level }
      end
    end
  end
  return out, n
end

-- Save a full list (it REPLACES the old one: an artefact sold or moved is gone).
function ataxia_artefactsStore(powers, n)
  local s = store()
  s.powers = powers or {}
  s.at = os.time()
  s.count = n
  if ataxia_saveSettings then ataxia_saveSettings(false) end
end

function ataxia_artefactsKnown()
  local s = ataxia.settings.artefacts
  return type(s) == "table" and type(s.powers) == "table"
end

-- Never scanned: the item catalog's artefacts, keyed to the KB (power, tier).
local function fromCatalog(power)
  if type(itemCatalog) ~= "table" or type(itemCatalog.items) ~= "table" or type(itemCatalog.kb) ~= "table" then
    return nil
  end
  for id, it in pairs(itemCatalog.items) do
    local e = type(it) == "table" and it.kbKey and itemCatalog.kb[it.kbKey]
    if type(e) == "table" and e.power == power then
      return { id = tonumber(id) or id, name = it.name, level = e.tier, from = "catalog" }
    end
  end
  return nil
end

-- The artefact that gives `power`, or nil: { id, name, level, from }. nil when the user switched it
-- off. "on" with nothing owned gives a record set by hand (level 1, or the level the user gave).
function ataxia_artefact(power)
  power = ataxia_artefactPowerKey(power)
  local s = ataxia.settings.artefacts
  local ov = type(s) == "table" and type(s.override) == "table" and s.override[power]
  if ov == "off" then return nil end
  local rec
  if ataxia_artefactsKnown() then
    rec = s.powers[power]
    if not rec then
      -- a power saved under its cut name (a scan before its full name was known)
      for k, v in pairs(s.powers) do
        if #k < #power and power:sub(1, #k) == k then rec = v; break end
      end
    end
    if rec then rec = { id = rec.id, name = rec.name, level = rec.level, from = "scan" } end
  else
    rec = fromCatalog(power)
  end
  if not rec and type(ov) == "string" and ov:match("^on") then
    rec = { name = "(set by hand)", level = tonumber(ov:match("^on (%d+)$")) or 1, from = "override" }
  end
  return rec
end

-- The level that sizes the effect: the artefact's own, else 1 (a power with no levels).
function ataxia_artefactLevel(power)
  local a = ataxia_artefact(power)
  if not a then return 0 end
  return tonumber(a.level) or 1
end

-- The effect size for our level from A.EFFECTS[power][field] ("pct", "add" or "mult"), else
-- `default`. A level above the table's length takes the last entry.
function ataxia_artefactSize(power, field, default)
  power = ataxia_artefactPowerKey(power)
  local lvl = ataxia_artefactLevel(power)
  local e = A.EFFECTS[power]
  local t = e and e[field]
  if lvl == 0 or type(t) ~= "table" or #t == 0 then return default end
  return t[math.min(lvl, #t)]
end

-- The multiplier on a BASE equilibrium time (the AB / wiki figure), and why. `form` is the Shikudo
-- form, or nil (default: ours, from GMCP). Quick-witted also speeds equilibrium, but by how much is
-- not known: it is named in the reason and left out of the number.
function ataxia_eqFactor(form)
  local f, why = 1, {}
  local pct = ataxia_artefactSize("faster_eq", "pct", nil)
  if pct then
    f = f * (1 - pct / 100)
    local a = ataxia_artefact("faster_eq")
    why[#why + 1] = (a and a.name or "faster_eq") .. " -" .. pct .. "%"
  end
  if form == nil and type(ataxia.vitals) == "table" then form = ataxia.vitals.form end
  if type(form) == "string" and form:lower():find("rain", 1, true) then
    f = f * A.RAIN_FACTOR
    why[#why + 1] = "Rain x" .. A.RAIN_FACTOR
  end
  if ataxia_hasTrait and ataxia_hasTrait("quick-witted") then
    why[#why + 1] = "quick-witted (size unknown, not counted)"
  end
  return f, (#why > 0 and table.concat(why, ", ") or "no equilibrium artefact")
end

-- A base equilibrium time in seconds -> ours.
function ataxia_eqSeconds(base, form)
  local f = ataxia_eqFactor(form)
  return (tonumber(base) or 0) * f
end

-- ---------------------------------------------------------------------------------------------
-- Reading the list (triggers 802 and 803) and the `aconfig artefact` alias (configs/036)
-- ---------------------------------------------------------------------------------------------

-- Trigger 802: the header row "Item ID   Item Name   Power   Level".
function ataxia_artefactHeader()
  ataxiaTemp.artefactRead = { at = (getEpoch and getEpoch()) or 0, lines = {} }
end

-- Trigger 803: a row, read only inside the window. Saved with every row: the list has no end
-- marker we can rely on (the closing dashes are the same as the opening ones).
function ataxia_artefactRow(line)
  local r = ataxiaTemp.artefactRead
  local nowT = (getEpoch and getEpoch()) or 0
  if type(r) ~= "table" or nowT - (r.at or 0) > WINDOW then return end
  if not ataxia_parseArtefactPowerRow(line) then return end
  r.at = nowT
  r.lines[#r.lines + 1] = line
  local powers, n = ataxia_artefactsFromLines(r.lines)
  ataxia_artefactsStore(powers, n)
  if not r.said and tempTimer then
    r.said = true
    tempTimer(1, function() ataxia_artefactReport(true) end)
  end
end

function ataxia_artefactScan()
  send("artefact power list owned", false)
end

-- Login (login/001): ask once, while nothing is saved.
function ataxia_artefactLogin()
  if ataxia_artefactsKnown() then return end
  if tempTimer then
    tempTimer(19, function() ataxia_artefactScan() end)
  end
end

-- `aconfig artefact <power> on|off|auto`. "on" may carry a level: "on 2".
function ataxia_artefactOverride(power, state)
  power = ataxia_artefactPowerKey(power)
  local s = store()
  if state == "auto" then s.override[power] = nil else s.override[power] = state end
  if ataxia_saveSettings then ataxia_saveSettings(false) end
end

local function echo(msg) if ataxiaEcho then ataxiaEcho(msg) end end

-- What we own that changes a number, and who reads it. `short`: one summary line (after a scan).
function ataxia_artefactReport(short)
  local s = ataxia.settings.artefacts
  if not ataxia_artefactsKnown() then
    echo("Artefacts not read yet" .. (fromCatalog("faster_eq") and " (the item catalog stands in)" or "")
      .. ". Read them: <white>aconfig artefact scan")
  end
  local f, why = ataxia_eqFactor("Oak")
  local fr = ataxia_eqFactor("Rain")
  echo(string.format("Equilibrium: base x%.2f (%s); in Rain x%.2f.", f, why, fr))
  if short then
    echo("Artefact powers saved: <white>" .. tostring(type(s) == "table" and s.count or 0)
      .. "<reset>. Details: <white>aconfig artefact")
    return
  end
  local keys = {}
  for k in pairs(A.EFFECTS) do keys[#keys + 1] = k end
  table.sort(keys)
  for _, k in ipairs(keys) do
    local a = ataxia_artefact(k)
    local ov = type(s) == "table" and s.override and s.override[k]
    if a or ov then
      local e = A.EFFECTS[k]
      echo(string.format("  %-18s %s%s -- %s; read by: %s", k,
        a and (a.name .. (a.level and (" L" .. a.level) or "")) or "<red>off",
        ov and (" <yellow>[" .. ov .. "]<reset>") or "", e.what, e.reader))
    end
  end
  echo("Switch one: <white>aconfig artefact <power> on|off|auto<reset>. Read the list again: <white>aconfig artefact scan")
end

function ataxia_artefactCommand(arg)
  arg = norm(arg)
  if arg == "" then return ataxia_artefactReport(false) end
  if arg == "scan" then return ataxia_artefactScan() end
  local power, state = arg:match("^(%S+)%s+(on%s*%d*)$")
  if not power then power, state = arg:match("^(%S+)%s+(off)$") end
  if not power then power, state = arg:match("^(%S+)%s+(auto)$") end
  if not power then
    echo("Usage: <white>aconfig artefact [scan | <power> on [level] | <power> off | <power> auto]")
    return
  end
  state = state:gsub("%s+", " ")
  ataxia_artefactOverride(power, state)
  local key = ataxia_artefactPowerKey(power)
  local a = ataxia_artefact(key)
  echo("Artefact power <white>" .. key .. "<reset>: " .. (a and ("<green>active<reset> (" .. a.name .. ")") or "<red>off"))
end
