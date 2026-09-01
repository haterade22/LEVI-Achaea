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

    Measured against `M.BOON_SEED` before committing to it. The counts below are the SNAPSHOT
    THEY WERE TAKEN FROM -- 297 described entries, pre-rebalance. The catalogue is 326/299 as
    of the 2026-09-01 changes; the ratios are what the argument rests on, not the totals, and
    re-measuring is a script away (`tools/` scratch, or just count in `010_Boon_Seed.lua`):

        battlerage procs   9/9  parse cleanly
        stat bonuses      18/22 parse cleanly
        resistances       11/16 parse cleanly

    So the exceptions below are the residue, not the design -- SIX entries against the community
    file's forty-seven, each with a note saying WHY the sentence cannot carry it. Do not "tidy"
    them back into prose parsing; they are here because a regex provably cannot tell the two
    numbers apart. (This said "nine" from v4.7.287 until a doc review counted them: the plan
    estimated nine and the implementation needed six. A count in a comment is a claim.)
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
  -- CHANGED 2026-09-01: was "Gain 3 dexterity but lose 2 constitution". Now a damage boon.
  -- Still an exception for the same reason -- two numbers, opposite signs, one sentence.
  ["Silvestri's Grace"] = { stat = { Damage = 25, Constitution = -1 } },
  ["Good Jera"]         = { stat = { Strength = 1, Constitution = 1 } },
  ["Rose of Pain"]      = { stat = { Intelligence = 3, Speed = 15 } },
  ["Dungeoneer"]        = { stat = { Damage = 5, Speed = 5 } },
  -- CONDITIONAL, not permanent: "infuses you FOR 60 SECONDS at the start of each new ripple".
  -- Held as a flat +30% it overstated the panel's headline for all but the first minute of every
  -- ripple -- the exact "conditional counted as unconditional" failure `_dmgGenericFrom` refuses
  -- for parsed sentences, which had been baked into the hand-written table instead.
  ["Furious Speed"]     = { stat = { Damage = 30 }, cond = "60s at each ripple start" },
}

local STAT_NAMES = {
  strength = "Strength", dexterity = "Dexterity", constitution = "Constitution",
  intelligence = "Intelligence",
}

-- Eight types, and the 2026-09-01 Mastery boons name eight to match -- six of them identically.
-- The two that differ are handled as ALIASES rather than by renaming a row:
--   `venom` -> Poison is CONFIRMED by our own catalogue, since Venom Mastery's description says
--     "poison damage" in so many words.
--   `arcane` gets its OWN row, NOT folded into Magical. Pairing them by elimination would be a
--     guess, and a guess here silently INFLATES a number the panel exists to be trusted on --
--     whereas a separate row asserts nothing and, if the two turn out to be the same thing, shows
--     you two rows to merge. `Antimagic Shell` and `Arcane Will` shipping in the same batch make
--     the pairing likely; likely is not read.
local RESIST_TYPES = {
  physical = "Physical", magical = "Magical", fire = "Fire", cold = "Cold",
  poison = "Poison", asphyxiation = "Asphyxiation", electric = "Electric", psychic = "Psychic",
  venom = "Poison", arcane = "Arcane",
  -- The catalogue says "magic" as often as "magical" ("10% magic, fire, cold, and poison
  -- resistance"), and only `magical` was a key -- so Stout and Shin Enhanced lost their
  -- Magical row while their other types resolved fine. A partial parse is the worst kind.
  magic = "Magical",
}

-- The DISTINCT display names, which is not the same list as the keys above -- `poison` and `venom`
-- both resolve to "Poison". Anything that iterates the types to write one row per type must walk
-- THIS, or an aliased type is written twice: the "All damage" fold below would have credited
-- Poison with the all-bonus once per alias.
local RESIST_ROWS = {}
do
  local seen = {}
  for _, t in pairs(RESIST_TYPES) do
    if not seen[t] then seen[t] = true; RESIST_ROWS[#RESIST_ROWS + 1] = t end
  end
  table.sort(RESIST_ROWS)
end

-- ---------------------------------------------------------------------------
-- Inputs
-- ---------------------------------------------------------------------------

-- Every boon claimed in the CURRENT run, with how many copies. Reads the same history the
-- `mnem boons` report does, so the window and the report can never disagree.
-- ONE ENTRY PER BOON, NOT PER CLAIM (deep review, v4.7.291). `_recordClaim` inserts a row for
-- every claim EVENT and never dedupes, so a boon echoed twice appeared twice here -- and
-- `bonusTotals` folded its description in once per row. The result was the base value multiplied
-- by the claim count, which is right only when a boon's echo happens to be an exact multiple of
-- its base. `Reckless Rage` is base 10% / echo 15%: claimed twice it reported +20% instead of
-- +15%. `Furious Speed` is worse -- its echo text DROPS the "20% resistance to all damage" clause
-- entirely, so the second claim was adding a resistance the upgraded form no longer grants.
-- The echo count is kept, because it selects the echo WORDING below.
function M._claimedBoons()
  local out, seen = {}, {}
  local h = M.history
  if not h or type(h.claims) ~= "table" then return out end
  for _, c in ipairs(h.claims) do
    if c.run == h.run and type(c.name) == "string" then
      local rec = seen[c.name]
      if rec then
        rec.echoes = math.max(rec.echoes, tonumber(c.echoes) or 1)
        rec.count = rec.count + 1
        rec.rarity = rec.rarity or c.rarity
      else
        rec = { name = c.name, echoes = tonumber(c.echoes) or 1, count = 1, rarity = c.rarity }
        seen[c.name] = rec
        out[#out + 1] = rec
      end
    end
  end
  -- `echoes` is what the claim RECORD said; `count` is how many times we saw it claimed. They
  -- normally agree, and where they do not the larger is the safer read of "how many do we hold".
  for _, r in ipairs(out) do r.echoes = math.max(r.echoes, r.count) end
  table.sort(out, function(a, b) return a.name < b.name end)
  return out
end

-- The wording for a boon, best source first: this run's own claim record (the live offer text),
-- then the all-time library, then the seed. Same ladder `_warnAttuneOnClaim` uses -- and the
-- fallback is load-bearing there for the same reason, so it is not belt-and-braces here either.
function M._bonusDesc(name, echoes)
  -- AN ECHOED BOON HAS ITS OWN SENTENCE. 38 seed entries carry `echo`, and it is not a multiplier
  -- of the base: `Reckless Rage` goes 10% -> 15%, and `Furious Speed`'s echo drops a whole clause.
  -- So when we hold two or more, that wording IS the description -- and where we have no echo text
  -- the base is used ONCE and nothing is scaled, because a multiplier we invented would be exactly
  -- the fabricated number this module exists to avoid.
  if (tonumber(echoes) or 1) >= 2 then
    local seed = M.BOON_SEED and M.BOON_SEED[name]
    if seed and seed.echo and seed.echo ~= "" then return seed.echo end
  end
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
-- Every damage type named in a fragment. A LIST is as common as a single type -- "an additional
-- 10% magic, fire, cold, and poison resistance" (Stout), "10% resistance to fire, cold, electric,
-- and magic damage" (Shin Enhanced) -- and the single-`%a+` patterns this used to have returned
-- nil for the first (all four resistances vanished from the panel) and captured only Fire from
-- the second (three of four silently dropped). Non-type words in the fragment ("and", "damage")
-- simply are not in the table, so no separator handling is needed.
-- Only "and" and a trailing "damage" may sit between the types; ANY other word means the capture
-- ran past the list and this is not a type list at all. That check is load-bearing: the pattern
-- `([%a,%s]-)%s*resistance` will happily span most of a sentence, and against Rose of Pain
-- ("...recovers 15% faster, but you suffer from permanent hallucinations, and your fire
-- resistance is reduced by 20%") it captured "faster, but you suffer ... and your fire" and
-- reported Fire +15 -- a number from an unrelated clause, with the sign inverted. Rejecting on an
-- unknown word makes the parser fall through to the branch that reads the sentence correctly.
local LIST_FILLER = { ["and"] = true, ["damage"] = true }

local function typesIn(fragment)
  local found = {}
  for w in (fragment or ""):gmatch("%a+") do
    local lw = w:lower()
    local t = RESIST_TYPES[lw]
    if t then
      found[#found + 1] = t
    elseif not LIST_FILLER[lw] then
      return {}   -- not a type list; let a later pattern have the sentence
    end
  end
  return found
end

function M._resistFrom(desc)
  if type(desc) ~= "string" then return nil end
  local out = {}

  -- Positive grants, three wordings, each allowing a comma list where the type sits.
  local n, list = desc:match("(%d+)%%%s+resistance to%s+([%a,%s]+)")
  if not n then n, list = desc:match("(%d+)%%%s+([%a,%s]-)%s*resistance") end
  if n then
    local types = typesIn(list)
    if #types > 0 then
      for _, t in ipairs(types) do out[t] = tonumber(n) end
      return out
    end
  end

  local t
  t, n = desc:match("(%a+)%s+resistance is increased by%s+(%d+)%%")
  if n and t and RESIST_TYPES[t:lower()] then
    out[RESIST_TYPES[t:lower()]] = tonumber(n)
    return out
  end

  -- "...and your fire resistance is reduced by 20%." (Rose of Pain). Parsed generically rather
  -- than pinned in BONUS_EXCEPTIONS: a penalty the panel drops reports a defence we do not have,
  -- and the sentence names its own number here perfectly well.
  t, n = desc:match("(%a+)%s+resistance is reduced by%s+(%d+)%%")
  if n and t and RESIST_TYPES[t:lower()] then
    out[RESIST_TYPES[t:lower()]] = -tonumber(n)
    return out
  end

  -- A WEAKNESS is a negative resistance and belongs on the same row, or the panel reports a
  -- defence we do not have. Two wordings, both live: "a 10% weakness to psychic damage"
  -- (Offspring's Error) and "you take 10% additional physical damage" (Violent Impulse).
  n, t = desc:match("(%d+)%%%s+weakness to%s+(%a+)")
  if not n then n, t = desc:match("[Yy]ou take%s+(%d+)%%%s+additional%s+(%a+)%s+damage") end
  if n and t and RESIST_TYPES[t:lower()] then
    out[RESIST_TYPES[t:lower()]] = -tonumber(n)
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

-- GENERIC outgoing damage: the number a player actually asks for, and it ADDS.
--
-- Measured across the described entries before writing a pattern (297 of them at the time; 299
-- after the 2026-09-01 rebalance), and the measurement is the
-- whole design. 35 boons mention dealing more damage; only SEVEN are the thing you would want
-- summed into one figure:
--
--   "You deal 25% more damage but all mana costs now cost health."    Blood Pact
--   "Deal 10% more damage but you can no longer benefit from..."      Reckless Rage
--   "You deal 1% bonus damage."                                      Hidden Gem
--   "Gain 30% bonus damage, but you take 10% additional physical..."  Violent Impulse
--   "You deal 12% increased damage, but the spells invoked..."        Wild Magic
--   "You deal 10% bonus damage on the ground but..."                  Ormyrr Claws
--   "Your damage dealt is increased by 5% and your balance..."        Dungeoneer
--
-- The rest fall into two groups that must NOT be added to that total:
--
--   CONDITIONAL -- real, but only sometimes. "You deal 20% bonus damage WHILE you possess the
--     chrono blur defence", "10% more damage WHEN above 90% mana", "15% more damage TO ENEMIES
--     whose health percent is lower than yours". Summing these produces a headline that is wrong
--     almost all the time, which on a panel read to make decisions is worse than showing nothing.
--     They are listed with their condition and left out of the arithmetic.
--
--   ABILITY-SPECIFIC -- "Your STERNUM STRIKES deal an additional 300% damage" (Blossom of Pain),
--     "Your PAEAN REFRAIN ... increased by 200%" (Warmarch), "Your DRACONIC BLAST ability does 25%
--     more damage". Same distinction `_procFrom` already draws, and for the same reason: these
--     fire on one ability, not on every swing. They do not match the patterns below at all,
--     because every pattern requires the subject to be YOU and the object to be BARE "damage".
--     A boon in this group still appears in the BOONS section -- it is unquantified, not hidden.
--
-- Returns { pct = n, cond = "<the governing clause>" or nil }.
function M._dmgGenericFrom(desc)
  if type(desc) ~= "string" then return nil end
  local n =
    desc:match("[Yy]ou deal%s+(%d+)%%%s+[%a]+%s+damage")
    or desc:match("[Yy]ou deal%s+(%d+)%%%s+damage")
    or desc:match("^[Dd]eal%s+(%d+)%%%s+[%a]+%s+damage")
    or desc:match("[Gg]ain%s+(%d+)%%%s+bonus damage")
    or desc:match("[Yy]our damage dealt is increased by%s+(%d+)%%")
  if not n then return nil end
  -- The condition, if the sentence carries one. Captured rather than merely detected: "conditional
  -- +20%" is nearly useless and "+20% while chrono blur is up" is actionable, and the clause is
  -- sitting right there in the text we already have.
  -- The clause can come BEFORE the number as easily as after it: `Cavalry` opens "When you are
  -- mounted, ... you deal 10% more damage", and looking only to the right of the word "damage"
  -- read that as unconditional and folded a mounted-only bonus into the always-on total.
  local cond = desc:match("damage%s+(while[^.]+)")
      or desc:match("damage%s+(when[^.]+)")
      or desc:match("damage%s+(against[^.]+)")
      or desc:match("damage%s+(to enemies[^.]+)")
      or desc:match("^([Ww]hen [^,]+),")
      or desc:match("^([Ww]hile [^,]+),")
      or desc:match("damage%s+(on the ground)")
  return { pct = tonumber(n), cond = cond }
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
  local offense = { total = 0, rows = {}, conditional = {} }

  for _, b in ipairs(M._claimedBoons()) do
    local desc = M._bonusDesc(b.name, b.echoes)
    local ex = M.BONUS_EXCEPTIONS[b.name]

    -- `Damage` is a PERCENTAGE, not a stat, so it is routed to the offense total rather than
    -- printed beside Strength and Constitution. It only ever arrives via an exception (a sentence
    -- carrying two numbers of opposite meaning), which is why it is peeled off here.
    local st = (ex and ex.stat) or M._statFrom(desc)
    if st and st.Damage then
      if ex and ex.cond then
        offense.conditional[#offense.conditional + 1] =
          { name = b.name, pct = st.Damage, cond = ex.cond }
      else
        offense.total = offense.total + st.Damage
        offense.rows[#offense.rows + 1] = { name = b.name, pct = st.Damage }
      end
      st = (function(t) local c = {}; for k, v in pairs(t) do if k ~= "Damage" then c[k] = v end end; return c end)(st)
    end
    addInto(stats, st)

    if ex and ex.resist then addInto(resists, ex.resist)
    else
      local r = M._resistFrom(desc)
      if r then addInto(resists, r) end
    end

    -- ALL-DAMAGE resistance. The percentage must be the one ADJACENT to the phrase, never just
    -- the first in the sentence: Ogre's Defence reads "You lose 2% critical strike chance, but you
    -- gain 10% resistance to all damage", and taking the first number credited it with 2% -- which
    -- is exactly the two-numbers-in-one-sentence trap `BONUS_EXCEPTIONS` exists for, reappearing
    -- in the one branch that was not reading its number positionally. Live panel showed +22% where
    -- the truth was +30%.
    if desc then
      local all = desc:match("(%d+)%%%s+resistance to all damage")
        or desc:match("(%d+)%%%s+resistance to all")
      if all then allResist = allResist + tonumber(all) end
    end

    addInto(dmg, M._dmgBoostFrom(desc))

    -- Generic damage, ADDITIVE (user, 2026-09-01). Only the always-on ones reach the total; a
    -- conditional bonus is recorded beside it with its clause so the headline stays honest.
    -- SKIPPED when an exception already supplied this boon's damage: both read the same sentence,
    -- and `Silvestri's Grace` ("You deal 25% more damage but lose 1 constitution") satisfies both,
    -- which totalled +50%. An exception exists precisely because the sentence cannot be parsed
    -- safely, so it is authoritative and the parser must stand down -- the same shape as the
    -- Poison alias double-count, one layer up.
    local g = (not (ex and ex.stat and ex.stat.Damage)) and M._dmgGenericFrom(desc) or nil
    if g then
      if g.cond then
        offense.conditional[#offense.conditional + 1] = { name = b.name, pct = g.pct, cond = g.cond }
      else
        offense.total = offense.total + g.pct
        offense.rows[#offense.rows + 1] = { name = b.name, pct = g.pct }
      end
    end

    local p = M._procFrom(desc)
    if p then procs[p.aff] = math.max(procs[p.aff] or 0, p.chance) end

    for _, c in ipairs((M._boonDrawbacks and M._boonDrawbacks(desc)) or {}) do
      costs[#costs + 1] = { cost = c, from = b.name }
    end
  end

  if allResist ~= 0 then
    for _, t in ipairs(RESIST_ROWS) do resists[t] = (resists[t] or 0) + allResist end
  end

  immune = (M.runImmunities and M.runImmunities()) or {}
  table.sort(offense.rows, function(a, b) return a.pct > b.pct end)
  table.sort(offense.conditional, function(a, b) return a.pct > b.pct end)
  return { stats = stats, resists = resists, procs = procs, immune = immune,
           costs = costs, dmg = dmg, offense = offense }
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

  -- OFFENSE, above the defensive blocks: it is the number you are usually reading the panel for.
  -- TOTAL first, then the boons that make it up, so the figure is auditable rather than asserted.
  local off = {}
  local O = T.offense or { total = 0, rows = {}, conditional = {} }
  if O.total ~= 0 then
    off[#off + 1] = { text = "TOTAL  " .. signed(O.total) .. "% damage", colour = "gold" }
  end
  for _, r in ipairs(O.rows) do
    off[#off + 1] = { text = "  " .. signed(r.pct) .. "%  " .. r.name, colour = "yellow" }
  end
  -- Conditional bonuses are shown but NOT summed. A headline that is right only while some
  -- defence happens to be up is worse than no headline, and the clause is what makes it usable.
  for _, r in ipairs(O.conditional) do
    off[#off + 1] = { text = "  " .. signed(r.pct) .. "%  " .. r.name .. "  <dim_grey>" .. r.cond,
                      colour = "dark_khaki" }
  end
  section("OFFENSE", off)

  -- RESISTANCES. When every type carries the SAME number there is nothing to compare, so the
  -- eight rows are collapsed to one -- which is what an "all damage" grant with no type-specific
  -- boon beside it produces, and it filled half the panel. The v4.7.287 reason for folding "all"
  -- into every type stands exactly as written: it exists so a reader comparing Fire against Cold
  -- does not have to add a hidden third row. Where there is no comparison to make, it buys
  -- nothing. A MIXED set still prints per type.
  local resists = {}
  local rkeys, same, first = sortedKeys(T.resists), true, nil
  for _, k in ipairs(rkeys) do
    if first == nil then first = T.resists[k] elseif T.resists[k] ~= first then same = false end
  end
  if same and first and first ~= 0 and #rkeys == #RESIST_ROWS then
    resists[1] = { text = "All types  " .. signed(first) .. "%", colour = "white" }
  else
    for _, k in ipairs(rkeys) do
      if T.resists[k] ~= 0 then
        resists[#resists + 1] = {
          text = k .. "  " .. signed(T.resists[k]) .. "%",
          colour = RESIST_COLOUR[k] or "white",
        }
      end
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

  -- AUDIT -- the game's own accounting, and the only thing on this panel that is MEASURED rather
  -- than derived from a sentence. Placed last of the numeric blocks: it is the check, not the
  -- headline. A delta appears only once there are two readings, because "no second reading yet"
  -- and "the boons bought nothing" are different answers and must not render alike.
  local aud = {}
  local A = M.audit or {}
  if A.current then
    local d = M._auditDelta and M._auditDelta() or nil
    local function scal(label, key, suffix)
      if type(A.current[key]) ~= "number" then return end
      local delta = d and d[key]
      aud[#aud + 1] = {
        text = label .. "  " .. A.current[key] .. (suffix or "")
          .. (delta and ("  (" .. signed(delta) .. " this run)") or ""),
        colour = "cyan",
      }
    end
    scal("Crit rate", "critRate", "%")
    scal("Crit bonus", "critBonus", "")
    scal("Celerity", "celerity", "")
    for _, k in ipairs(sortedKeys(A.current.resists)) do
      local delta = d and d.resists[k]
      aud[#aud + 1] = {
        text = "  " .. k .. "  " .. A.current.resists[k] .. "%"
          .. (delta and ("  (" .. signed(delta) .. ")") or ""),
        colour = RESIST_COLOUR[k] or "light_grey",
      }
    end
  end
  section("AUDIT (measured)", aud)

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
