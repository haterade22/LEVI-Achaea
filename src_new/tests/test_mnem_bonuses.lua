--- test_mnem_bonuses.lua -- the Bonuses aggregation (mnemosyne/011_Bonuses.lua)
--
-- The PURE half of the bonuses panel. `012_Bonuses_Window` is Geyser and needs `main`, so it is
-- not tested here -- the same split as 005_Ripple_Map (tested) vs 006_Ripple_Map_Window (not).
--
-- What these pin is the design decision: the numbers are DERIVED FROM THE DESCRIPTION rather than
-- from a hand-maintained name->amount table, with a small exceptions list for sentences a regex
-- provably cannot read. Every wording asserted below is one that actually appears in
-- 010_Boon_Seed.lua -- they were sampled out of it before the parsers were written.

require("mock_mudlet")

ataxia = ataxia or {}
ataxia.mnemosyne = ataxia.mnemosyne or {}
local M = ataxia.mnemosyne

-- Minimal stand-ins for the collaborators 011 reads. Each is the real contract, not a shortcut:
-- _histBoonInfo returns (rarity, description); boonInfo returns a record; BOON_SEED is a map.
M.history = { run = 1, claims = {}, affixes = {}, boonLibrary = {} }
M.BOON_SEED = M.BOON_SEED or {}
function M._histBoonInfo(name) return nil, nil end
function M.boonInfo(name) return (M.history.boonLibrary or {})[name] end
function M.runImmunities() return M._testImmune or {} end
function M._boonDrawbacks(desc) return M._testCosts or {} end
function M._spiritGate(desc)
  return type(desc) == "string" and desc:match("attuned to ([A-Z][%a']+)") or nil
end
function M._attuned(spirit) return M._testAttuned end
function M.echo() end

dofile("src_new/scripts/levi_ataxia/levi/ataxia/mnemosyne/011_Bonuses.lua")

local function reset()
  M.history = { run = 1, claims = {}, affixes = {}, boonLibrary = {} }
  M.BOON_SEED = {}
  M._testImmune, M._testCosts, M._testAttuned = nil, nil, nil
end

local function claim(name, desc, rarity, echoes)
  table.insert(M.history.claims, { run = 1, name = name, rarity = rarity, echoes = echoes })
  M.BOON_SEED[name] = { description = desc, rarity = rarity }
end

local function sectionRows(title)
  for _, s in ipairs(M.bonusSections()) do
    if s.title == title then return s.rows end
  end
  return nil
end

-- ─── Parsers, against wordings taken from the real catalogue ─────────────────

describe("bonus parsers read the seed's own wordings", function()
  it("reads all three resistance phrasings", function()
    -- "Gain 25% resistance to electric damage."          (Argent Scales)
    expect(M._resistFrom("Gain 25% resistance to electric damage.").Electric).toBe(25)
    -- "...grants 10% physical resistance."               (Battle-Scarred)
    expect(M._resistFrom("The memory of the War Veil grants 10% physical resistance.").Physical).toBe(10)
    -- "Your poison resistance is increased by 66% but..."(Corrupted Blood)
    expect(M._resistFrom("Your poison resistance is increased by 66% but you suffer nausea.").Poison).toBe(66)
  end)

  it("reads all four stat phrasings", function()
    expect(M._statFrom("The Patron of Heroes increases your strength by 1.").Strength).toBe(1)
    expect(M._statFrom("Gain 1 points of constitution.").Constitution).toBe(1)
    expect(M._statFrom("Your strength is increased by 5, but you suffer stupidity.").Strength).toBe(5)
    expect(M._statFrom("Your stonefist defence grants you an additional 3 strength while active.").Strength).toBe(3)
  end)

  it("ignores prose that names no number it understands", function()
    expect(M._resistFrom("You are immune to the hellsight affliction.")).toBe(nil)
    expect(M._statFrom("The Smith's raw strength allows your attacks to bypass shields.")).toBe(nil)
    expect(M._resistFrom(nil)).toBe(nil)
  end)
end)

-- ON-HIT vs ABILITY-SPECIFIC is a real distinction, not tidiness: an ability proc fires only when
-- you use that one ability, where these ride every swing.
describe("on-hit procs are gated on 'your attacks'", function()
  it("takes a generic on-hit proc", function()
    local p = M._procFrom("Your attacks have a 5% chance to afflict the target with weakness.")
    expect(p.aff).toBe("weakness")
    expect(p.chance).toBe(5)
  end)

  it("REFUSES an ability-specific proc with the same phrasing", function()
    -- Dragonfire: the identical "chance to afflict the target with" clause, but it only fires on
    -- the blast. Folding it in would read as though it applied to ordinary attacks.
    expect(M._procFrom("Your draconic blast attack is imbued with a Red Dragon's breath, granting it a 20% chance to afflict the target with fear.")).toBe(nil)
    expect(M._procFrom("Your scream ability has a 20% chance to afflict the target with sensitivity.")).toBe(nil)
  end)
end)

-- ─── Aggregation ────────────────────────────────────────────────────────────

describe("bonus totals", function()
  it("sums the same stat across boons", function()
    reset()
    claim("Heroic Strength", "The Patron of Heroes increases your strength by 1.")
    claim("Meathead", "Your strength is increased by 5, but you suffer permanent stupidity.")
    expect(M.bonusTotals().stats.Strength).toBe(6)
  end)

  -- The EXCEPTIONS are the point of the design: a sentence with two numbers of opposite sign
  -- cannot be read by one pattern, and taking the first would report a penalty as a bonus.
  it("an exception overrides the parsed value", function()
    reset()
    claim("Earthen Will", "Gain 15% physical resistance, but lose 10% magical resistance.")
    local r = M.bonusTotals().resists
    expect(r.Physical).toBe(15)
    expect(r.Magical).toBe(-10)   -- the parser alone would never produce a negative
  end)

  -- "All damage" folds into every type rather than getting its own row: at the point of use
  -- "+15% to everything" and "+15% fire" are the same fact, and a reader comparing rows should
  -- not have to add a hidden third.
  it("folds an all-damage resistance into every type", function()
    reset()
    claim("Onyx Scales", "Gain 15% resistance to all damage.")
    claim("Azure Scales", "Gain 25% resistance to cold damage.")
    local r = M.bonusTotals().resists
    expect(r.Cold).toBe(40)     -- 25 specific + 15 all
    expect(r.Fire).toBe(15)     -- a type with no boon of its own still shows the all-bonus
  end)

  -- ALIASES (v4.7.288). The 2026-09-01 Mastery boons name eight damage types to our eight, and
  -- two are worded differently: `venom` is our Poison -- confirmed by our own catalogue, since
  -- Venom Mastery's text says "poison damage" -- and `arcane` gets its OWN row rather than being
  -- folded into Magical, because pairing them is a guess and a guess inflates a number silently.
  it("reads an aliased damage type onto the row it belongs to", function()
    reset()
    claim("Venom Mastery", "Your venom damage dealt is increased by 15% and you gain 10% venom resistance.")
    local T = M.bonusTotals()
    expect(T.dmg.Poison).toBe(15)
    expect(T.resists.Poison).toBe(10)
  end)

  -- The alias created a trap: two KEYS resolve to one ROW, so anything iterating the type table
  -- to write one row per type writes the aliased row twice. The all-damage fold did exactly that
  -- the moment the alias was added, silently doubling Poison.
  it("gives an aliased type the all-damage bonus exactly ONCE", function()
    reset()
    claim("Onyx Scales", "Gain 15% resistance to all damage.")
    expect(M.bonusTotals().resists.Poison).toBe(15)  -- not 30, once per alias
  end)

  it("keeps type damage boosts out of the stat totals", function()
    reset()
    claim("Fire Mastery", "Your fire damage dealt is increased by 15% and you gain 10% fire resistance.")
    local T = M.bonusTotals()
    expect(T.dmg.Fire).toBe(15)
    expect(T.resists.Fire).toBe(10)  -- both halves of the one sentence, in the right sections
    expect(T.stats.Damage).toBe(nil) -- NOT folded into the generic damage stat
  end)

  -- The names are chosen so the BIGGER chance is seen FIRST: boons are folded in sorted order, so
  -- a plain last-write-wins would agree with `max` whenever the larger one happened to sort last.
  -- Breaking `math.max` back to an assignment passed against the obvious naming.
  it("takes the highest chance when two boons proc the same affliction", function()
    reset()
    claim("Ancient Minia", "Your attacks have a 12% chance to afflict the target with weakness.")
    claim("Zealous Minia", "Your attacks have a 5% chance to afflict the target with weakness.")
    expect(M.bonusTotals().procs.weakness).toBe(12)
  end)

  it("survives a claimed boon we have no description for", function()
    reset()
    table.insert(M.history.claims, { run = 1, name = "Unknown Thing" })
    local ok = pcall(M.bonusTotals)
    expect(ok).toBeTrue()
  end)

  it("ignores claims from a PREVIOUS run", function()
    reset()
    claim("Heroic Strength", "The Patron of Heroes increases your strength by 1.")
    M.history.claims[1].run = 0   -- last run's claim
    expect(M.bonusTotals().stats.Strength).toBe(nil)
  end)
end)

-- ─── Sections ───────────────────────────────────────────────────────────────

describe("bonus sections", function()
  it("omits a section with no rows rather than printing an empty heading", function()
    reset()
    expect(#M.bonusSections()).toBe(0)
  end)

  -- A boon we hold but cannot use is the one most worth SEEING, so it is marked, not hidden.
  it("marks a Shaman boon INERT when its spirit is not attuned", function()
    reset()
    claim("Full Mettle Alchemist", "While attuned to Aspar, your attacks nourish you.", "uncommon")
    M._testAttuned = false
    local rows = sectionRows("BOONS")
    expect(rows[1].text:find("INERT", 1, true) ~= nil).toBeTrue()
    expect(rows[1].colour).toBe("dim_grey")
  end)

  -- THREE-STATE, and the middle state matters: nil means "cannot tell" (non-Shaman, or SPIRIT
  -- BINDINGS never read). Rendering that as INERT would be a confident wrong answer on a panel.
  it("does NOT mark it inert when attunement cannot be read", function()
    reset()
    claim("Full Mettle Alchemist", "While attuned to Aspar, your attacks nourish you.", "uncommon")
    M._testAttuned = nil
    expect(sectionRows("BOONS")[1].text:find("INERT", 1, true)).toBe(nil)
  end)

  -- Every other section is upside. A panel that shows only upside lies by arrangement.
  it("always shows COSTS when a boon has one", function()
    reset()
    claim("Meathead", "Your strength is increased by 5, but you suffer permanent stupidity.")
    M._testCosts = { "stupidity" }
    local rows = sectionRows("COSTS")
    expect(rows ~= nil).toBeTrue()
    expect(rows[1].text:find("stupidity", 1, true) ~= nil).toBeTrue()
  end)

  it("lists this run's affixes first", function()
    reset()
    table.insert(M.history.affixes, { run = 1, name = "Haemophiliac" })
    claim("Heroic Strength", "The Patron of Heroes increases your strength by 1.")
    expect(M.bonusSections()[1].title).toBe("AFFIXES")
  end)
end)

-- Test files share ONE Lua state and run in sorted order, so the stubs above outlive this file
-- (`test_mnem_bonuses` sorts before `test_mnemosyne`). Drop them: every one is a `M.x = ...`
-- assignment in a real module, so nil lets the next file's dofile install the genuine article,
-- and the `or {}` idiom in 007_History rebuilds `history` cleanly.
M.history, M.BOON_SEED = nil, nil
M._histBoonInfo, M.boonInfo, M.runImmunities = nil, nil, nil
M._boonDrawbacks, M._spiritGate, M._attuned, M.echo = nil, nil, nil, nil
M._testImmune, M._testCosts, M._testAttuned = nil, nil, nil
