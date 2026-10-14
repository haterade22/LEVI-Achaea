--[[mudlet
type: script
name: Alchemist Robes
hierarchy:
- Levi_Ataxia
- LEVI
- Ataxia
- Ataxia
- System-related
- Class Things
attributes:
  isActive: 'yes'
  isFolder: 'no'
packageName: ''
]]--

-- ROBES (Alchemy, ABADMIN 3, equilibrium). ROBES SUMMON weaves the robes; ROBES IMBUE WITH <up to
-- four symbols> WIPES the old symbols and applies new ones, each symbol at most once. Each symbol
-- protects against one damage type. Robes are not a DEF line, so SSC cannot keep them: like
-- METABOLISE (deffing/001), defup and login send them ourselves.
--
-- Which four: `aconfig robes auto` (the default) imbues the four damage types that cost us the
-- most, from bashStats.incomingByType ("Health lost: N (physical blunt)."), filled from the
-- default set (lead iron gold mercury) until there is enough data. A fresh Mnemosyne run resets
-- bashStats, so inside the tower the ranking is this run's. Inside the tower a changed top four
-- re-imbues itself, at most once per ataxia_ROBES_REIMBUE_GAP: an imbue costs an equilibrium,
-- i.e. one attack.

ataxiaTemp = ataxiaTemp or {}

-- Substring of the game's damage type -> symbol. "raw" and "unblockable" have no symbol.
ataxia_ROBES_SYMBOL_FOR = {
  { "blunt", "lead" }, { "cutting", "iron" }, { "magic", "salt" }, { "psychic", "tin" },
  { "electric", "copper" }, { "asphyx", "sulphur" }, { "cold", "silver" }, { "fire", "gold" },
  { "poison", "mercury" },
}
ataxia_ROBES_DEFAULT = { "lead", "iron", "gold", "mercury" }
ataxia_ROBES_MIN_HITS = 5        -- typed hits before the ranking outranks the default set
ataxia_ROBES_REIMBUE_GAP = 120   -- seconds between automatic re-imbues in the tower
ataxia_ROBES_THROTTLE = 10       -- login + defup inside 10s send once

function ataxia_robesSymbolFor(dtype)
  dtype = tostring(dtype or ""):lower()
  for _, pair in ipairs(ataxia_ROBES_SYMBOL_FOR) do
    if dtype:find(pair[1], 1, true) then return pair[2] end
  end
  return nil
end

local function has(list, v)
  for _, x in ipairs(list) do
    if x == v then return true end
  end
  return false
end

local function isSymbol(word)
  for _, pair in ipairs(ataxia_ROBES_SYMBOL_FOR) do
    if pair[2] == word then return true end
  end
  return false
end

-- "auto" (default), false (off), or a list of fixed symbols.
function ataxia_robesSetting()
  local v = ataxia.settings and ataxia.settings.robesImbue
  if v == false then return false end
  if type(v) ~= "string" or v == "" or v == "auto" then return "auto" end
  local out = {}
  for word in v:lower():gmatch("%a+") do
    if isSymbol(word) and not has(out, word) and #out < 4 then out[#out + 1] = word end
  end
  if #out == 0 then return "auto" end
  return out
end

-- The four symbols to imbue now, and where they came from ("fixed", "damage", "default").
function ataxia_robesPlan()
  local setting = ataxia_robesSetting()
  if setting == false then return nil, "off" end
  if type(setting) == "table" then return setting, "fixed" end
  local out, src = {}, "default"
  if bashStats and (bashStats.incomingHits or 0) >= ataxia_ROBES_MIN_HITS and bashStats_incomingRanked then
    for _, row in ipairs(bashStats_incomingRanked()) do
      local sym = ataxia_robesSymbolFor(row[1])
      if sym and not has(out, sym) and #out < 4 then
        out[#out + 1] = sym
        src = "damage"
      end
    end
  end
  for _, sym in ipairs(ataxia_ROBES_DEFAULT) do
    if #out >= 4 then break end
    if not has(out, sym) then out[#out + 1] = sym end
  end
  return out, src
end

-- Order does not matter to the robes; compare sets, not lists.
local function planKey(list)
  local copy = {}
  for i, s in ipairs(list) do copy[i] = s end
  table.sort(copy)
  return table.concat(copy, " ")
end

function ataxia_robesImbue(why, force)
  if not ataxia_isClass("Alchemist") then return false end
  local plan = ataxia_robesPlan()
  if not plan then return false end
  local key = planKey(plan)
  if not force and key == ataxiaTemp.robesKey then return false end
  local now = getEpoch()
  local last = ataxiaTemp.robesImbuedAt
  if not force and last and now - last >= 0 and now - last < ataxia_ROBES_THROTTLE then return false end
  ataxiaTemp.robesKey = key
  ataxiaTemp.robesImbuedAt = now
  send("queue add eq robes imbue with " .. table.concat(plan, " "), false)
  return true
end

-- Defup and login: summon once per session, then imbue if the set is not already on.
function ataxia_robesSummon(why, force)
  if not ataxia_isClass("Alchemist") then return false end
  if ataxia_robesSetting() == false then return false end
  if force or not ataxiaTemp.robesSummoned then
    ataxiaTemp.robesSummoned = true
    ataxiaTemp.robesKey = nil -- a new set of robes carries no symbols
    send("queue add eq robes summon", false)
  end
  ataxia_robesImbue(why, force)
  return true
end

-- Called on every typed hit we take (bashStats_recordIncoming). Tower only, auto only.
function ataxia_robesCheck()
  if not (ataxiaBasher and ataxiaBasher.inMnemosyne) then return false end
  if ataxia_robesSetting() ~= "auto" then return false end
  if not ataxia_isClass("Alchemist") then return false end
  if not bashStats or (bashStats.incomingHits or 0) < ataxia_ROBES_MIN_HITS then return false end
  local last = ataxiaTemp.robesImbuedAt
  local now = getEpoch()
  if last and now - last >= 0 and now - last < ataxia_ROBES_REIMBUE_GAP then return false end
  return ataxia_robesImbue("damage")
end

function ataxia_setRobes(arg)
  arg = arg and arg:lower():gsub("^%s+", ""):gsub("%s+$", "") or ""
  if arg == "" then
    local setting = ataxia_robesSetting()
    local plan, src = ataxia_robesPlan()
    local mode = setting == false and "OFF" or (setting == "auto" and "auto" or "fixed")
    ataxiaEcho("Robes: " .. mode .. (plan and (" -- next imbue: " .. table.concat(plan, " ") .. " (" .. src .. ")") or "")
      .. " -- on now: " .. (ataxiaTemp.robesKey or "unknown"))
    return
  end
  if arg == "off" then
    ataxia.settings.robesImbue = false
    ataxiaEcho("Robes OFF -- defup will no longer summon or imbue them.")
    return
  end
  if arg == "now" then
    ataxia_robesImbue("now", true)
    return
  end
  if arg == "summon" then
    ataxia_robesSummon("summon", true)
    return
  end
  if arg == "auto" then
    ataxia.settings.robesImbue = "auto"
  else
    local bad = {}
    for word in arg:gmatch("%a+") do
      if not isSymbol(word) then bad[#bad + 1] = word end
    end
    if #bad > 0 then
      ataxiaEcho("Not a robe symbol: " .. table.concat(bad, ", ")
        .. ". Use lead iron salt tin copper sulphur silver gold mercury.")
      return
    end
    ataxia.settings.robesImbue = arg
  end
  local plan, src = ataxia_robesPlan()
  ataxiaEcho("Robes set to " .. ataxia.settings.robesImbue .. " -- imbuing " .. table.concat(plan, " ") .. " (" .. src .. ").")
  ataxia_robesImbue("set")
end
