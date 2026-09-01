--[[mudlet
type: script
name: Bonuses
hierarchy:
- Levi_Ataxia
- Ataxia
- Mnemosyne
attributes:
  isActive: 'yes'
  isFolder: 'no'
packageName: ''
]]--

--[[
    ============================================================================
    WHAT ARE OUR BOONS ACTUALLY GIVING US?  (v4.7.287, `mnem bonuses`)
    ============================================================================

    A run's boons arrive one at a time across an hour, each announced once on a screen that is
    gone a second later. Nothing in the package could answer "what am I currently immune to, how
    much fire resistance do I have, what is my strength right now" -- the offer-screen immunity
    note (v4.7.224) says it ONCE, at the moment of choosing, and `mnem boons` prints a flat list
    of names with no arithmetic.

    This aggregates the claimed set into the eight things worth knowing at a glance. It is PURE:
    it returns plain tables and touches no Geyser, so it is unit-tested. `012_Bonuses_Window`
    renders it, exactly as `005_Ripple_Map` is tested and `006_Ripple_Map_Window` is not.

    DERIVED FROM THE DESCRIPTION, NOT FROM A NAME TABLE
    ---------------------------------------------------
    The community window this was modelled on keeps ~47 hand-written `name -> amount` entries.
    Our house rule says otherwise (v4.7.264 attune-gating, v4.7.186 damage-suppression affixes):
    **parse the sentence, because the sentence always names its own numbers, and a name table
    goes stale on the entry after the last one someone added.**

    Measured against `M.BOON_SEED` (297 described boons) before committing to it:

        battlerage procs   9/9  parse cleanly
        stat bonuses      18/22 parse cleanly
        resistances       11/16 parse cleanly

    So the exceptions below are the residue, not the design -- nine entries against forty-seven,
    each with a note saying WHY the sentence cannot carry it. Do not "tidy" them back into prose
    parsing; they are here because a regex provably cannot tell the two numbers apart.
]]--

local M = ataxia.mnemosyne

-- ---------------------------------------------------------------------------
-- Exceptions: descriptions a regex cannot honestly read
-- ---------------------------------------------------------------------------
--
-- Two shapes end up here:
--   * TWO NUMBERS, opposite meanings -- "Gain 15% physical resistance, but lose 10% magical
--     resistance." A single pattern cannot say which belongs to which, and picking the first is
--     how you report a penalty as a bonus (the gear-audit `generate N%% less` trap, v4.7.208).
--   * TWO STATS, one number -- "increases your strength and constitution by an additional 1."
--
-- `Careless Whisperer` is deliberately ABSENT. The community file maps it to Cold +10; our seed
-- says "You are immune to masochism, hallucinations, and paranoia...". One of the two is wrong
-- and we have not confirmed which, so it contributes no resistance row rather than a guessed one.
M.BONUS_EXCEPTIONS = {
  ["Earthen Will"]      = { resist = { Physical = 15, Magical = -10 } },
  ["Silvestri's Grace"] = { stat = { Dexterity = 3, Constitution = -2 } },
  ["Good Jera"]         = { stat = { Strength = 1, Constitution = 1 } },
  ["Rose of Pain"]      = { stat = { Intelligence = 3, Speed = 15 } },
  ["Dungeoneer"]        = { stat = { Damage = 5, Speed = 5 } },
  ["Furious Speed"]     = { stat = { Damage = 30 } },
}

local STAT_NAMES = {
  strength = "Strength", dexterity = "Dexterity", constitution = "Constitution",
  intelligence = "Intelligence",
}

local RESIST_TYPES = {
  physical = "Physical", magical = "Magical", fire = "Fire", cold = "Cold",
  poison = "Poison", asphyxiation = "Asphyxiation", electric = "Electric", psychic = "Psychic",
}

-- ---------------------------------------------------------------------------
-- Inputs
-- ---------------------------------------------------------------------------

-- Every boon claimed in the CURRENT run, with how many copies. Reads the same history the
-- `mnem boons` report does, so the window and the report can never disagree.
function M._claimedBoons()
  local out = {}
  local h = M.history
  if not h or type(h.claims) ~= "table" then return out end
  for _, c in ipairs(h.claims) do
    if c.run == h.run and type(c.name) == "string" then
      out[#out + 1] = { name = c.name, echoes = tonumber(c.echoes) or 1, rarity = c.rarity }
    end
  end
  table.sort(out, function(a, b) return a.name < b.name end)
  return out
end

-- The wording for a boon, best source first: this run's own claim record (the live offer text),
-- then the all-time library, then the seed. Same ladder `_warnAttuneOnClaim` uses -- and the
-- fallback is load-bearing there for the same reason, so it is not belt-and-braces here either.
function M._bonusDesc(name)
  local _, desc = M._histBoonInfo(name)
  if desc and desc ~= "" then return desc end
  local lib = M.boonInfo and M.boonInfo(name)
  if lib and lib.description and lib.description ~= "" then return lib.description end
  local seed = M.BOON_SEED and M.BOON_SEED[name]
  return seed and seed.description or nil
end

-- ---------------------------------------------------------------------------
-- Parsers -- one per family, each built from wordings actually present in the seed
-- ---------------------------------------------------------------------------

-- Resistances come in THREE wordings, all live in the catalogue:
--   "Gain 25% resistance to electric damage."
--   "The memory of the War Veil grants 10% physical resistance."
--   "Your poison resistance is increased by 66% but ..."
-- The type and the number swap places between them, which is why this is three patterns rather
-- than one clever one.
function M._resistFrom(desc)
  if type(desc) ~= "string" then return nil end
  local out = {}
  local n, t = desc:match("(%d+)%%%s+resistance to%s+(%a+)")
  if not n then n, t = desc:match("(%d+)%%%s+(%a+)%s+resistance") end
  if not n then
    t, n = desc:match("(%a+)%s+resistance is increased by%s+(%d+)%%")
  end
  if n and t and RESIST_TYPES[t:lower()] then
    out[RESIST_TYPES[t:lower()]] = tonumber(n)
    return out
  end
  return nil
end

-- Stat wordings, again all present in the seed:
--   "The Patron of Heroes increases your strength by 1."
--   "Gain 1 points of constitution."
--   "Your strength is increased by 5, but ..."
--   "grants you an additional 3 strength while active"
function M._statFrom(desc)
  if type(desc) ~= "string" then return nil end
  local out = {}
  local s, n = desc:match("increases your (%a+) by%s+(%d+)")
  if not s then s, n = desc:match("[Yy]our (%a+) is increased by%s+(%d+)") end
  if not s then n, s = desc:match("[Gg]ain (%d+) points? of (%a+)") end
  if not s then n, s = desc:match("additional (%d+) (%a+)") end
  if s and n and STAT_NAMES[s:lower()] then
    out[STAT_NAMES[s:lower()]] = tonumber(n)
    return out
  end
  return nil
end

-- Type-specific OUTGOING damage: "Your fire damage dealt is increased by 15% and you gain 10%
-- fire resistance."
--
-- Kept apart from the generic damage bonuses that land in STATS, because they are different
-- facts: a Damage stat lifts everything, this lifts one type. Folding them would tell a
-- Blademaster his void damage was up when only his fire was.
function M._dmgBoostFrom(desc)
  if type(desc) ~= "string" then return nil end
  local t, n = desc:match("[Yy]our (%a+) damage dealt is increased by%s+(%d+)%%")
  if t and n and RESIST_TYPES[t:lower()] then
    return { [RESIST_TYPES[t:lower()]] = tonumber(n) }
  end
  return nil
end

-- ON-HIT affliction procs: "Your attacks have a 5% chance to afflict the target with weakness."
--
-- DELIBERATELY GATED ON "your attacks" (v4.7.287). The same "chance to afflict the target with"
-- phrasing also covers ability-specific procs -- the draconic blast breaths, `scream`, `confront`
-- -- and those are a different fact: they fire only when you use that one ability, where these
-- ride every swing. Folding them together would make the panel read as though a Dragon's blast
-- chance applied to ordinary attacks.
function M._procFrom(desc)
  if type(desc) ~= "string" then return nil end
  if not desc:lower():find("your attacks", 1, true) then return nil end
  local n, aff = desc:match("(%d+)%%%s+chance to afflict the target with%s+(%a+)")
  if not n then return nil end
  return { aff = aff:lower(), chance = tonumber(n) }
end

-- ---------------------------------------------------------------------------
-- Aggregation
-- ---------------------------------------------------------------------------

local function addInto(totals, tbl)
  for k, v in pairs(tbl or {}) do totals[k] = (totals[k] or 0) + v end
end

-- Resistance totals per damage type. An "All damage" grant is folded into EVERY type rather than
-- shown as its own row (the community window's call, and it is the right one): "+15% to
-- everything" and "+15% fire" are the same fact at the point of use, and a reader comparing two
-- rows should not have to add a hidden third.
function M.bonusTotals()
  local stats, resists, procs, immune, costs, dmg = {}, {}, {}, {}, {}, {}
  local allResist = 0

  for _, b in ipairs(M._claimedBoons()) do
    local desc = M._bonusDesc(b.name)
    local ex = M.BONUS_EXCEPTIONS[b.name]

    if ex and ex.stat then addInto(stats, ex.stat)
    else addInto(stats, M._statFrom(desc)) end

    if ex and ex.resist then addInto(resists, ex.resist)
    else
      local r = M._resistFrom(desc)
      if r then addInto(resists, r) end
    end

    if desc and desc:lower():find("resistance to all damage", 1, true) then
      allResist = allResist + (tonumber(desc:match("(%d+)%%")) or 0)
    end

    addInto(dmg, M._dmgBoostFrom(desc))

    local p = M._procFrom(desc)
    if p then procs[p.aff] = math.max(procs[p.aff] or 0, p.chance) end

    for _, c in ipairs((M._boonDrawbacks and M._boonDrawbacks(desc)) or {}) do
      costs[#costs + 1] = { cost = c, from = b.name }
    end
  end

  if allResist ~= 0 then
    for _, t in pairs(RESIST_TYPES) do resists[t] = (resists[t] or 0) + allResist end
  end

  immune = (M.runImmunities and M.runImmunities()) or {}
  return { stats = stats, resists = resists, procs = procs, immune = immune,
           costs = costs, dmg = dmg }
end

-- Is this boon INERT right now? Only a Shaman attunement can make one so, and the answer is
-- three-state: nil means "cannot tell" (non-Shaman, or SPIRIT BINDINGS never read), which must
-- never be rendered as "inert" -- a confident wrong answer on a panel is worse than a blank.
function M._bonusInert(name)
  local spirit = M._spiritGate and M._spiritGate(M._bonusDesc(name))
  if not spirit then return nil end
  if M._attuned(spirit) == false then return spirit end
  return nil
end

-- ---------------------------------------------------------------------------
-- Sections -- the render contract: { title, rows = { {text, colour} } }
-- ---------------------------------------------------------------------------

local RARITY_COLOUR = {
  common = "green", uncommon = "deep_sky_blue", rare = "dark_violet",
  -- `gold`, not the community file's `orange`: the orange family is reserved for new code.
  epic = "gold", legendary = "yellow", mythic = "red",
}

-- Thematic per damage type so the type is recognised by colour rather than read. NOTE the
-- community file uses `silver` for Physical and `silver` IS NOT IN our colour table -- that table
-- wholesale replaces Mudlet's, so it would throw on every render (CHANGELOG v4.7.136 names it
-- specifically). `light_grey` is the substitute; every name here is verified present.
local RESIST_COLOUR = {
  Physical = "light_grey", Magical = "medium_orchid", Fire = "firebrick",
  Cold = "light_blue", Poison = "lime_green", Asphyxiation = "dim_grey",
  Electric = "yellow", Psychic = "medium_purple",
}

local function sortedKeys(t)
  local k = {}
  for key in pairs(t or {}) do k[#k + 1] = key end
  table.sort(k)
  return k
end

local function signed(n)
  return (n > 0 and "+" or "") .. tostring(n)
end

function M.bonusSections()
  local T = M.bonusTotals()
  local out = {}

  local function section(title, rows)
    if #rows > 0 then out[#out + 1] = { title = title, rows = rows } end
  end

  -- AFFIXES -- what the ripple is doing TO us, first because it is the thing that kills.
  local affixes = {}
  local h = M.history
  for _, a in ipairs((h and h.affixes) or {}) do
    if a.run == (h and h.run) then
      affixes[#affixes + 1] = { text = a.name, colour = "indian_red" }
    end
  end
  section("AFFIXES", affixes)

  -- BOONS -- rarity-coloured, with INERT called out. A boon we hold but cannot use is the one
  -- most worth seeing, which is why it is marked rather than hidden.
  local boons = {}
  for _, b in ipairs(M._claimedBoons()) do
    local inert = M._bonusInert(b.name)
    local text = b.name .. (b.echoes > 1 and (" x" .. b.echoes) or "")
    if inert then text = text .. "  INERT (" .. inert .. ")" end
    boons[#boons + 1] = {
      text = text,
      colour = inert and "dim_grey" or (RARITY_COLOUR[(b.rarity or ""):lower()] or "white"),
    }
  end
  section("BOONS", boons)

  local stats = {}
  for _, k in ipairs(sortedKeys(T.stats)) do
    stats[#stats + 1] = { text = k .. "  " .. signed(T.stats[k]), colour = "gold" }
  end
  section("STATS", stats)

  local resists = {}
  for _, k in ipairs(sortedKeys(T.resists)) do
    if T.resists[k] ~= 0 then
      resists[#resists + 1] = {
        text = k .. "  " .. signed(T.resists[k]) .. "%",
        colour = RESIST_COLOUR[k] or "white",
      }
    end
  end
  section("RESISTANCES", resists)

  local dmg = {}
  for _, k in ipairs(sortedKeys(T.dmg)) do
    dmg[#dmg + 1] = {
      text = k .. "  " .. signed(T.dmg[k]) .. "%",
      colour = RESIST_COLOUR[k] or "white",
    }
  end
  section("DMG BOOSTS", dmg)

  local immune = {}
  for _, aff in ipairs(sortedKeys(T.immune)) do
    immune[#immune + 1] = { text = aff .. "  (" .. tostring(T.immune[aff]) .. ")", colour = "spring_green" }
  end
  section("IMMUNE TO", immune)

  local procs = {}
  for _, aff in ipairs(sortedKeys(T.procs)) do
    procs[#procs + 1] = { text = aff .. "  " .. T.procs[aff] .. "% per hit", colour = "medium_sea_green" }
  end
  section("ON-HIT PROCS", procs)

  -- COSTS last, and never omitted: every other section is upside, and a panel that only shows
  -- upside is a panel that lies by arrangement (v4.7.238 -- a grant can also carry a price).
  local costs = {}
  for _, c in ipairs(T.costs) do
    costs[#costs + 1] = { text = c.cost .. "  (" .. c.from .. ")", colour = "indian_red" }
  end
  section("COSTS", costs)

  return out
end
